#include "widget.h"
#include "ui_widget.h"

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


void Widget::on_Exit_clicked()
{

}

void Widget::on_Start_clicked()
{
    gameInfo->Init();
    gameInfo->show();
    this->hide();
}
