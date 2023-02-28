#include "MainWindow.h"
#include "ui_MainWindow.h"
#include "Character.h"
#include <QHBoxLayout>
#include <QLabel>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow() { delete ui; }

void MainWindow::Init()
{
    Character c;
    c.Init();

    QLabel *label = new QLabel(this);
    QHBoxLayout *layout = new QHBoxLayout();
    label->setText(std::to_string(c.CalcShownAttack()).c_str());
    layout->addWidget(label);
    setLayout(layout);


    return;
}
