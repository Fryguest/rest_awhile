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
            int x = i * (mParam.width + mParam.gapSize) + mParam.ePoint.x;
            int y = j * (mParam.width + mParam.gapSize) + mParam.ePoint.y;
            QRectF rect = QRectF(QPointF(x, y), QSize(mParam.width, mParam.width));
            painter.drawRect(rect);
        }
    }

    if (true)
    {
        painter.setPen(Qt::black);
        int gox[8] = {1,1,2,2,-2,-2,-1,-1};
        int goy[8] = {2,-2,1,-1,1,-1,2,-2};
        for (int i = 0; i < mParam.size;i++)
        {
            for (int j = 0; j < mParam.size; j++)
            {
                if (v[i][j]) continue;
                int cnt = 0;
                for (int d = 0; d < 8; d++)
                {
                    if (i + gox[d] < 0 or i + gox[d] >= mParam.size or j + goy[d] < 0 or j + goy[d] >= mParam.size) continue;
                    if (v[i + gox[d]][j + goy[d]] == 0) cnt++;
                }
                int x = i * (mParam.width + mParam.gapSize) + mParam.ePoint.x;
                int y = j * (mParam.width + mParam.gapSize) + mParam.ePoint.y;
                QRectF rect = QRectF(QPointF(x, y), QSize(mParam.width, mParam.width));
                painter.drawText(rect, Qt::AlignCenter, std::to_string(cnt).c_str());
            }
        }
    }
//    for (int i = 0; i < path.size(); i++)
//    {
//        int x = path[i].x * (mParam.width + mParam.gapSize) + mParam.ePoint.x;
//        int y = path[i].y * (mParam.width + mParam.gapSize) + mParam.ePoint.y;
//        QRectF rect = QRectF(QPointF(x, y), QSize(mParam.width, mParam.width));
//        if (i == path.size() - 1) painter.setPen(QColor(Qt::black));
//        else painter.setPen(QColor(Qt::white));
//        painter.drawText(rect, Qt::AlignCenter, std::to_string(i+1).c_str());
//    }
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
    Point2d lastPoint = path.back();
    int dx = abs(x - lastPoint.x), dy = abs(y - lastPoint.y);
    if (dx + dy == 3 and (dx == 2 or dy == 2))
    {
        path.emplace_back(x, y);
    }

    return;
}
void MainWindow::Repaint()
{
    if (path.size() > 1)
        ui->backOneStepButton->setDisabled(false);
    else
        ui->backOneStepButton->setDisabled(true);

    if (path.size() == mParam.size * mParam.size)
        ui->nextMissionButton->setDisabled(false);
    else
        ui->nextMissionButton->setDisabled(true);

    v.clear();
    v.resize(mParam.size, vector<int>(mParam.size, 0));
    for (int i = 0; i < path.size() - 1; i++)
    {
        v[path[i].x][path[i].y] = 1;
    }
    v[path.back().x][path.back().y]=2;
    update();
}

void MainWindow::mousePressEvent(QMouseEvent* event)
{
    if(event->button()==Qt::LeftButton)
    {
        Solve(Point2d(event->pos().x(), event->pos().y()));
        Repaint();
    }
    return;
}

void MainWindow::InitMission()
{
    v.clear();
    v.resize(mParam.size, vector<int>(mParam.size, 0));
    v[0][0] = 2;
    path.clear();
    path.emplace_back(0,0);

    {
        int x = mParam.ePoint.x + mParam.size * (mParam.width + mParam.gapSize) - mParam.gapSize;
        int y = mParam.ePoint.y + mParam.size * (mParam.width + mParam.gapSize) - mParam.gapSize;
        ui->backOneStepButton->setGeometry(x + 30, y - 77, 75, 23);
        ui->backOneStepButton->setDisabled(true);
        ui->resetButton->setGeometry(x + 30, y - 50, 75, 23);
        ui->nextMissionButton->setDisabled(true);
        ui->nextMissionButton->setGeometry(x + 30, y - 23, 75, 23);
    }
    Repaint();
}

void MainWindow::Init()
{
    mParam.size = 5;
    InitMission();
    return;
}

void MainWindow::on_backOneStepButton_clicked()
{
    path.pop_back();
    Repaint();
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

