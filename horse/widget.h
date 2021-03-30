#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include "mainwindow.h"
namespace Ui {
class Widget;
}

class Widget : public QWidget
{
    Q_OBJECT

public:
    explicit Widget(QWidget *parent = 0);
    ~Widget();
    void setGameInfo(MainWindow* gameInfo)
    {
        this->gameInfo = gameInfo;
    }

private slots:


    void on_Exit_clicked();

    void on_Start_clicked();

private:
    MainWindow* gameInfo;
    Ui::Widget *ui;
};

#endif // WIDGET_H
