#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QPainter>
#include <QMouseEvent>
#include <iostream>
using namespace std;

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::paintEvent(QPaintEvent *)
{
    QPainter painter(this);

    for (int i = 0; i < mParam.size;i++)
    {
        for (int j = 0; j < mParam.size; j++)
        {
            if (v[i][j] == 2)
            {
                painter.setPen(Qt::black);
                painter.setBrush(Qt::red);
            }
            else if (v[i][j] == 1)
            {
                painter.setPen(Qt::black);
                painter.setBrush(Qt::black);
            }
            else
            {
                painter.setPen(Qt::black);
                painter.setBrush(QBrush(QColor(0,0,0,0)));
            }
            painter.drawRect(QRectF(QPointF(i * (mParam.width + mParam.gapSize) + mParam.ePoint.x, j * (mParam.width + mParam.gapSize) + mParam.ePoint.y), QSize(mParam.width, mParam.width)));
        }
    }
}

void MainWindow::Solve(Point2d pixelPoint)
{
    auto Cal = [&, this](const Point2d& p, int &x, int &y){
        if (p.x < mParam.ePoint.x or p.y < mParam.ePoint.y) return false;
        if ((p.x - mParam.ePoint.x) % (mParam.width + mParam.gapSize) >= mParam.width) return false;
        if ((p.y - mParam.ePoint.y) % (mParam.width + mParam.gapSize) >= mParam.width) return false;
        x = (p.x - mParam.ePoint.x) / (mParam.width + mParam.gapSize);
        y = (p.y - mParam.ePoint.y) / (mParam.width + mParam.gapSize);
        return x >= 0 and x < mParam.size and y >= 0 and y < mParam.size;
    };
    int x, y;
    if (!Cal(pixelPoint, x, y)) return;
    if (v[x][y]) return;
    int dx = abs(x - lastPoint.x), dy = abs(y - lastPoint.y);
    if (dx + dy == 3 and (dx == 2 or dy == 2))
    {
        v[lastPoint.x][lastPoint.y]=1;
        lastPoint.x = x;
        lastPoint.y = y;
        v[lastPoint.x][lastPoint.y]=2;
    }

    int cnt = 0;
    for (int i = 0; i < mParam.size; i ++)
    {
        for (int j = 0; j < mParam.size; j ++)
        {
            if (v[i][j])
            {
                cnt++;
            }
        }
    }

    if (cnt == mParam.size * mParam.size)
    {
        ui->nextMissionButton->setDisabled(false);
    }

    return;
}

void MainWindow::mousePressEvent(QMouseEvent* event)
{
    if(event->button()==Qt::LeftButton)
    {
        Solve(Point2d(event->pos().x(), event->pos().y()));
        update();
    }
    return;
}

void MainWindow::InitMission()
{
    v.clear();
    v.resize(mParam.size, vector<int>(mParam.size, 0));
    lastPoint = Point2d(0,0);
    v[lastPoint.x][lastPoint.y] = 2;

    {
        int x = mParam.ePoint.x + mParam.size * (mParam.width + mParam.gapSize) - mParam.gapSize;
        int y = mParam.ePoint.y + mParam.size * (mParam.width + mParam.gapSize) - mParam.gapSize;
        ui->resetButton->setGeometry(x + 30, y - 50, 75, 23);
        ui->nextMissionButton->setDisabled(true);
        ui->nextMissionButton->setGeometry(x + 30, y - 23, 75, 23);
    }
    update();
}

void MainWindow::Init()
{
    mParam.size = 5;
    InitMission();
    return;
}

void MainWindow::on_nextMissionButton_clicked()
{
    mParam.size++;
    InitMission();
}

void MainWindow::on_resetButton_clicked()
{
    InitMission();
}

