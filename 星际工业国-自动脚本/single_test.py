import threading
import queue
import keyboard
import time
import cv2
import numpy as np
import mss
import win32api
import win32con
import easyocr
import win32gui

# ===== 状态 =====
running = False
stop_flag = False
worker_thread = None

# ===== Boss 列表 =====
bosses = [
    (4140, 876),
    (4140, 996),
    (4140, 1100),
    (4140, 1250),
    (4140, 1350),
    (4140, 1480),
]

# ===== 截图队列 =====
screenshot_requests = queue.Queue()
screenshot_results = queue.Queue()

# ===== 截图函数（工作线程请求）=====
def screenshot_region(region):
    screenshot_requests.put(region)
    # 阻塞等待结果
    return screenshot_results.get()

# ===== MSS 初始化移至线程内部 =====
def screenshot_thread():
    """主线程截图服务"""
    local_sct = mss.mss()  # 每个线程独立的 mss 实例
    while True:
        region = screenshot_requests.get()  # 阻塞等待截图请求
        if region is None:
            break
        x, y, w, h = region
        monitor = {"left": x, "top": y, "width": w, "height": h}
        img = np.array(local_sct.grab(monitor))
        screen = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
        cv2.imwrite(f"{x}_{y}_{w}_{h}.png", screen)
        screenshot_results.put(screen)

# 启动截图线程（主线程中）    
threading.Thread(target=screenshot_thread, daemon=True).start()

# 初始化 EasyOCR 读取器（只需初始化一次）
reader = easyocr.Reader(['ch_sim', 'en'])  # 支持中文和英文

boss_list_buttons = [
    (5000, 1930),
    (5000, 1828),
    (5000, 1726),
    (5000, 1624),
    (5000, 1522),
    (5000, 1420),
    (5000, 1318),
]

# for button in boss_list_buttons:
#     # 截取按钮区域
#     screen = screenshot_region((button[0], button[1], 134, 66))

#     # OCR 识别文字
#     results = reader.readtext(screen)
#     for (bbox, text, prob) in results:
#         print(f'OCR 结果: {text} (置信度: {prob:.2f})')

#     # 检查是否包含“阶”
#     contains_jie = any("阶" in text for (_, text, _) in results)

#     if not contains_jie:
#         print(f'按钮位置: {button} - 不包含“阶”')
#         continue  # 跳过，检查下一个按钮

def check_text_in_screen(x, y, w, h, target):
    screen = screenshot_region((x, y, w, h))
    results = reader.readtext(screen)
    for (bbox, text, prob) in results:
        print(f'OCR 结果: {text} (置信度: {prob:.2f})')
        if target in text:
            return True
    return False


# level_screen = screenshot_region((4433, 1467, 180, 60))
# level_results = reader.readtext(level_screen)
# for (_, text, _) in level_results:
#     print(f'OCR 结果: {text}')
#     if text.isdigit():
#         boss_level = int(text)
#         break
# print(f"当前 BOSS 等级: {boss_level}")

#print(check_text_in_screen(7350, 540, 250, 80, "Lv"))


hwnd = win32gui.FindWindow(None, "星际工业国")
def click_w(hwnd, pos):
    if stop_flag:
        return False

    x, y = pos
    x -= 3840 # 转换为窗口坐标

    # 转换为 lParam
    lParam = win32api.MAKELONG(x, y)
    # 发送点击消息（后台）
    win32gui.PostMessage(hwnd, win32con.WM_LBUTTONDOWN, win32con.MK_LBUTTON, lParam)
    time.sleep(0.02)
    win32gui.PostMessage(hwnd, win32con.WM_LBUTTONUP, 0, lParam)
    time.sleep(0.6)
    return True

click_w(hwnd, (7429, 575))