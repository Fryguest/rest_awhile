#include "widget.h"
#include "ui_widget.h"
#include "Formula.h"
#include "Item.h"

Widget::Widget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::Widget)
{
    ui->setupUi(this);
}

Widget::~Widget()
{
    delete ui;
}
