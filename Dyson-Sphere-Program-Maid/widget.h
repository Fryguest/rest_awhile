#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <memory>
#include <QLineEdit>
#include <QLabel>
#include <QPushButton>
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
    void Init();
    void InitRequestList();
    void AddInputLineEdit();
    void ShowInputLineEdit();
    void Cal();

private:
    std::vector<std::pair<std::shared_ptr<QLineEdit>,std::shared_ptr<QLineEdit>>> requestInputList;
    std::shared_ptr<Maid> mpMaid;
    std::shared_ptr<QPushButton> mpStartCalButton;
    std::shared_ptr<QLabel> mpResultLabel;
};

#endif // WIDGET_H
