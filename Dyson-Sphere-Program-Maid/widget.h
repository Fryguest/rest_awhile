#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <memory>
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
    void Start();

private:
    std::shared_ptr<Maid> mpMaid;
};

#endif // WIDGET_H
