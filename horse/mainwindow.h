#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <vector>
#include <queue>
#include "common_structer.h"

namespace Ui {
class MainWindow;
}

struct MainParam
{
    Point2d ePoint = Point2d(10,10); // 棋盘左上角的点
    int width = 50; // 格子的长宽(目前是正方形)
    int gapSize = 5; // 格子之间的间隙大小
    int size = 5; // 格子数量
};
class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    void Init();
    void InitMission();
    void Solve(Point2d pixelPoint);

private:
    std::vector<std::vector<int>> v;
    Point2d lastPoint;
    MainParam mParam;

protected:
    void paintEvent(QPaintEvent *event);
    void mousePressEvent(QMouseEvent *);

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private slots:
    void on_nextMissionButton_clicked();
    void on_resetButton_clicked();

private:
    Ui::MainWindow *ui;

};

#endif // MAINWINDOW_H

