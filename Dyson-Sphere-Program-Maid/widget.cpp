#include "widget.h"
#include "ui_widget.h"
#include "Formula.h"
#include "Item.h"
#include <QObject>
#include <iostream>

using namespace std;
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

void Widget::ShowInputLineEdit()
{
    for (int i = 1; i <= requestInputList.size(); i++)
    {
        requestInputList[i - 1].first->move(100, i * 100);
        requestInputList[i - 1].second->move(300, i * 100);
    }

    mpStartCalButton->move(100, (requestInputList.size() + 1) * 100);
    mpResultLabel->move(100, (requestInputList.size() + 2) * 100);
}

void Widget::AddInputLineEdit()
{
    shared_ptr<QLineEdit> pItem = make_shared<QLineEdit>(this);
    shared_ptr<QLineEdit> pNum = make_shared<QLineEdit>(this);
    pNum->setValidator(new QDoubleValidator(0,1e9,2,this));
    requestInputList.emplace_back(pItem, pNum);
    ShowInputLineEdit();
    return;
}

void Widget::InitRequestList()
{
    requestInputList.clear();
    this->AddInputLineEdit();
    return;
}

void Widget::Cal()
{
    vector<ItemWithNum> requestList;
    for (auto request : requestInputList)
    {
        string name = request.first->text().toStdString();
        double num = request.second->text().toDouble();
        shared_ptr<Item> pItem;
        if (mpMaid->FindItem(name, pItem))
            requestList.emplace_back(*pItem, num);
    }
    vector<ItemWithNum> resultList = mpMaid->CalcRequest(requestList);

    string result = "";
    for (auto p : resultList)
    {
        result += p.first.name + " " + to_string(p.second) + "\n";
    }
    mpResultLabel->setText(QString::fromStdString(result));
    mpResultLabel->show();
    return;
}

void Widget::Init()
{
    mpStartCalButton = make_shared<QPushButton>("开始计算",this);
    QObject::connect(mpStartCalButton.get(), &QPushButton::clicked, this, &Widget::Cal);

    mpResultLabel = make_shared<QLabel>(this);
    mpResultLabel->hide();

    mpMaid = std::make_shared<Maid>();
    mpMaid->Init();
    InitRequestList();
    return;
}
