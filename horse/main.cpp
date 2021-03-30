#include "widget.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    Widget w;
    w.show();

    MainWindow* w1 = new MainWindow();
    w.setGameInfo(w1);
    return a.exec();
}

