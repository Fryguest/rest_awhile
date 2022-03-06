#include "widget.h"
#include "ui_widget.h"
#include "Item.h"
#include <QObject>
#include <QCompleter>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <QVBoxLayout>

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
    for (unsigned i = 1; i <= requestInputList.size(); i++)
    {
        requestInputList[i - 1].first->move(100, i * 50);
        requestInputList[i - 1].second->move(300, i * 50);
    }

    mpStartCalButton->move(100, (requestInputList.size() + 1) * 50);
    mpAddProductionButton->move(100, (requestInputList.size() + 1) * 50 + 25);
    mpSwitchFormulaButton->move(100, (requestInputList.size() +1 ) * 50 + 50);


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
    for (int i = 0; i< 3;i++)
    {
        while(auto child = mpResultLayout[i]->takeAt(0))
        {
            QWidget* pWidget = child->widget();
            pWidget->deleteLater();
            delete child;
        }
    }

    for (auto result : resultList)
    {
        QLabel* pName = new QLabel(this);
        pName->setMinimumHeight(15);
        QLabel* pNum = new QLabel(this);
        pNum->setMinimumHeight(15);
        pName->setText(QString::fromStdString(result.first->name));
        {
            ostringstream sout;
            sout<<result.second;
            pNum->setText(QString::fromStdString(sout.str()));
        }
        if (result.first->level >= 2)
        {
            int num = mpResultLayout[2]->count()/2;
            mpResultLayout[2]->addWidget(pName, num, 0);
            mpResultLayout[2]->addWidget(pNum, num, 1);
        }
        else
        {
            int num = mpResultLayout[result.first->level]->count()/2;
            mpResultLayout[result.first->level]->addWidget(pName, num, 0);
            mpResultLayout[result.first->level]->addWidget(pNum, num, 1);
        }
    }
    for (int i = 0;i<3;i++)
    {
        mpQScrollAreaVec[i]->widget()->resize(220, mpResultLayout[i]->count() * 10 + 10);
    }


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

void Widget::SwitchFormula()
{
    mpMaid->SwitchFormula();
    Cal();
    return;
}

void Widget::Init()
{
    mpMaid = std::make_shared<Maid>();
    mpMaid->Init();

    mpStartCalButton = make_shared<QPushButton>("开始计算",this);
    QObject::connect(mpStartCalButton.get(), &QPushButton::clicked, this, &Widget::Cal);

    mpResultLayout.resize(3);
    mpQScrollAreaVec.resize(3);
    for (int i = 0; i< 3;i++)
    {
        mpQScrollAreaVec[i] = make_shared<QScrollArea>(this);
        QLabel* pWidget = new QLabel(this);
        mpResultLayout[i] = make_shared<QGridLayout>(pWidget);
        mpResultLayout[i]->setSpacing(0);

        mpQScrollAreaVec[i]->setAlignment(Qt::AlignTop);
        mpQScrollAreaVec[i]->setWidget(pWidget);
        mpQScrollAreaVec[i]->show();
    }

    mpQScrollAreaVec[2]->move(500, 50);
    mpQScrollAreaVec[2]->resize(250,400);

    mpQScrollAreaVec[1]->move(800, 50);
    mpQScrollAreaVec[1]->resize(250,400);

    mpQScrollAreaVec[0]->move(1100, 50);
    mpQScrollAreaVec[0]->resize(250,400);

    mpAddProductionButton = make_shared<QPushButton>("添加产物", this);
    QObject::connect(mpAddProductionButton.get(), &QPushButton::clicked, this, &Widget::AddInputLineEdit);

    mpSwitchFormulaButton = make_shared<QPushButton>("切换高/低级公式",this);
    QObject::connect(mpSwitchFormulaButton.get(), &QPushButton::clicked, this, &Widget::SwitchFormula);

    InitRequestList();
    return;
}
