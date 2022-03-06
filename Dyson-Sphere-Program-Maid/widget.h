#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <memory>
#include <QLineEdit>
#include <QLabel>
#include <QPushButton>
#include <QStringList>
#include <QScrollArea>
#include <QGridLayout>
#include "Maid.h"

namespace Ui {
class Widget;
}

class Widget : public QWidget
{
    Q_OBJECT

public:
    explicit Widget(QWidget *parent = 0);
    ~Widget();

private:
    Ui::Widget *ui;

public:
    void ShowResult(const std::vector<ItemWithNum>&);
    void Init();
    void InitRequestList();
    void AddInputLineEdit();
    void SetLayout();
    void Cal();
    void SwitchFormula();

private:
    std::vector<std::pair<std::shared_ptr<QLineEdit>,std::shared_ptr<QLineEdit>>> requestInputList;
    std::shared_ptr<Maid> mpMaid;
    std::shared_ptr<QPushButton> mpStartCalButton; //按钮：开始计算
    std::shared_ptr<QPushButton> mpAddProductionButton; //按钮： 添加一行最终产物
    std::shared_ptr<QPushButton> mpSwitchFormulaButton; //按钮： 切换高/低级公式
    std::shared_ptr<QStringList> mpItemNameList; //输入框自动补全
    std::vector<std::shared_ptr<QScrollArea>> mpQScrollAreaVec;
    std::vector<std::shared_ptr<QGridLayout>> mpResultLayout;
};

#endif // WIDGET_H
