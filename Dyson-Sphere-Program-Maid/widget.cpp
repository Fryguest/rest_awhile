#include "widget.h"
#include "ui_widget.h"
#include "Item.h"
#include <QObject>
#include <QCompleter>
#include <iostream>
#include <iomanip>
#include <sstream>

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

void Widget::SetLayout()
{
    for (int i = 1; i <= requestInputList.size(); i++)
    {
        requestInputList[i - 1].first->move(100, i * 50);
        requestInputList[i - 1].second->move(300, i * 50);
    }

    mpStartCalButton->move(100, (requestInputList.size() + 1) * 50);
    mpResultLabel->move(500, 50);
    mpAddProductionButton->move(100, requestInputList.size() * 50 + 25);
}

void Widget::AddInputLineEdit()
{
    shared_ptr<QLineEdit> pItem = make_shared<QLineEdit>(this);
    pItem->setPlaceholderText("最终产物");
    pItem->show();
    pItem->setCompleter(new QCompleter(*mpItemNameList));
    shared_ptr<QLineEdit> pNum = make_shared<QLineEdit>(this);
    pNum->setPlaceholderText("每分钟产量");
    pNum->show();
    pNum->setValidator(new QDoubleValidator(0,1e9,2,this));
    requestInputList.emplace_back(pItem, pNum);
    SetLayout();
    return;
}

void Widget::InitRequestList()
{
    mpItemNameList = make_shared<QStringList>();
    vector<string> itemNameList = mpMaid->GetItemNameList();
    for (string name : itemNameList)
    {
        mpItemNameList->append(name.c_str());
    }

    requestInputList.clear();
    this->AddInputLineEdit();
    return;
}

void Widget::ShowResult(const vector<ItemWithNum>& resultList)
{
    string result = "";
    for (auto p : resultList)
    {
        ostringstream sout;
        sout<<left<<setw(20)<< p.first->name<<right<<setw(20)<<p.second;
        cout<<sout.str()<<endl;
        result+=sout.str()+"\n";
    }
    mpResultLabel->setText(QString::fromStdString(result));
    mpResultLabel->show();
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
            requestList.emplace_back(pItem, num);
    }
    this->ShowResult(mpMaid->CalcRequest(requestList));
    return;
}

void Widget::Init()
{
    mpMaid = std::make_shared<Maid>();
    mpMaid->Init();

    mpStartCalButton = make_shared<QPushButton>("开始计算",this);
    QObject::connect(mpStartCalButton.get(), &QPushButton::clicked, this, &Widget::Cal);

    mpResultLabel = make_shared<QLabel>(this);
    mpResultLabel->hide();

    mpAddProductionButton = make_shared<QPushButton>("添加产物", this);
    QObject::connect(mpAddProductionButton.get(), &QPushButton::clicked, this, &Widget::AddInputLineEdit);

    InitRequestList();
    return;
}
