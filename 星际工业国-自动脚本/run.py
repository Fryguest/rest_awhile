import threading
import queue
import keyboard
import time
import cv2
import numpy as np
import mss
import win32api
import win32con
import win32gui
import easyocr

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

def check_text_in_screen(x, y, w, h, target):
    screen = screenshot_region((x, y, w, h))
    results = reader.readtext(screen)
    for (bbox, text, prob) in results:
        print(f"OCR 结果: {text} (置信度: {prob:.2f})")
        if target.casefold() in text.casefold():
            print(f"找到目标文本: {text}")
            return True
    return False

def read_first_number_in_screen(x, y, w, h):
    screen = screenshot_region((x, y, w, h))
    results = reader.readtext(screen)
    for (_, text, _) in results:
        if text.isdigit():
            return int(text)
    return None

# ===== 截图函数（工作线程请求）=====
def screenshot_region(region):
    screenshot_requests.put(region)
    # 阻塞等待结果
    return screenshot_results.get()

# ===== 点击函数（win32）=====
# def click(pos):
#     if stop_flag:
#         return False
#     x, y = pos
#     win32api.SetCursorPos((x, y))
#     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
#     time.sleep(0.02)
#     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
#     time.sleep(0.6)
#     return True

hwnd = win32gui.FindWindow(None, "星际工业国")
def click(pos):
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

# ===== 检查停止 =====
def check_stop():
    return stop_flag

# ===== 等待“确定”按钮 =====
def wait_for_ok(timeout=600):
    start = time.time()

    while time.time() - start < timeout:
        if stop_flag:
            return False

        # 截取按钮区域
        screen = screenshot_region((6300, 1900, 300, 300))

        # OCR 识别文字
        results = reader.readtext(screen)

        # 检查是否包含“确定”
        for (bbox, text, prob) in results:
            if "确定" in text:
                return True

        time.sleep(0.3)
    return False

# ===== 切换 BOSS 列表按钮位置 =====
boss_list_buttons = [
    (5000, 1930),
    (5000, 1827),
    (5000, 1724),
    (5000, 1621),
    (5000, 1518),
    (5000, 1415),
    (5000, 1312),
    (5000, 1209),
    (5000, 1105),
    (5000, 997),
    (5000, 884),
]

# ===== 用户设定的最大 BOSS 等级 =====
MAX_BOSS_LEVEL = 34  # 可根据需要调整

# ===== 主流程 =====
def run():
    global running
    print(">>> 开始")
    running = True
    count = 0
    while running:
        for button in boss_list_buttons:
            print(f'按键位置: {button}')
            if check_stop():
                return

            if not check_text_in_screen(button[0], button[1], 134, 66, "阶"):
                print(f'按钮位置: {button} - 不包含“阶”， 跳过')
                continue

            # 点击切换按钮
            if not click((button[0] + 67, button[1] + 33)):
                return

            # 遍历当前 BOSS 列表
            for boss in bosses:
                time.sleep(1)  # 等待界面更新
                if check_stop():
                    return

                if not click(boss):
                    return
                
                boss_level = read_first_number_in_screen(4433, 1467, 180, 60)
                if boss_level is not None:
                    print(f"当前 BOSS 等级: {boss_level}")
                    if boss_level > MAX_BOSS_LEVEL:
                        print(f"跳过等级 {boss_level} 的 BOSS")
                        continue
                else:
                    print("未识别到 BOSS 等级，继续执行")

                if not check_text_in_screen(4570, 1850, 165, 65, "接取"):
                    print("未找到“接取”按钮，跳过当前 BOSS")
                    continue

                if not click((4657, 1887)):
                    return  # 接取
                if not click((4544, 1890)):
                    return  # 前往
                if not click((5923, 1941)):
                    return  # 探索
                if not click((5627, 891)):
                    return  # 狩猎
                if not click((5738, 857)):
                    return  # 出征

                wait_for_ok()

                if not click((6397, 2004)):
                    return  # 确定
                if not click((4657, 1887)):
                    return  # 提交

        count += 1
        print(f">>> 完成一轮 (总计: {count})")
    running = False

# ===== 等待“占领”按钮 =====
def wait_for_ok_2():

    while True:
        if stop_flag:
            return False
        if check_text_in_screen(6295, 1837, 220, 80, "占领"):
            return True
        time.sleep(0.5)
    return False

def clear_boss_list():
    global running
    print(">>> 开始清理星球列表")
    running = True
    while running:
        time.sleep(1)  # 等待界面更新
        # if not check_text_in_screen(7350, 540, 250, 80, "Lv"):
        #     print("清理完毕")
        #     break


        if not click((7429, 575)):
            return  # 点击第一颗星球
        if not click((5758, 796)):
            return  # 点击占领
        if not click((6020, 860)):
            return  # 点击补充
        if not click((5730, 860)):
            return  # 点击出征
        
        wait_for_ok_2()
        if not click((6405, 1885)):
            return  # 点击占领
        
    running = False

# ===== 启动狩猎 =====
def start():
    global worker_thread, stop_flag
    stop_flag = False
    worker_thread = threading.Thread(target=run)
    worker_thread.daemon = True
    worker_thread.start()

# ===== 启动清理星球列表 =====
def start_clear():
    global worker_thread, stop_flag
    stop_flag = False
    worker_thread = threading.Thread(target=clear_boss_list)
    worker_thread.daemon = True
    worker_thread.start()

# ===== 停止 =====
def stop():
    global stop_flag
    print(">>> 停止")
    stop_flag = True

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

# ===== 热键 =====
keyboard.add_hotkey("F1", start)
keyboard.add_hotkey("F2", stop)

keyboard.add_hotkey("F3", start_clear)

print("F1 启动（重开） | F2 停止")
keyboard.wait()