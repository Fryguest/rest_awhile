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

    for (unsigned i = 1; i <= outsourceInputList.size(); i++)
    {
        outsourceInputList[i - 1]->move(100, i * 50 + requestInputList.size() * 50 + 100);
    }

    mpAddOutsourceButton->move(100, (outsourceInputList.size() + 1) * 50 + (requestInputList.size() + 1) * 50 + 25);

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

void Widget::AddOutsourceLineEdit()
{
    shared_ptr<QLineEdit> pItem = make_shared<QLineEdit>(this);
    pItem->setPlaceholderText("外部输入产物");
    pItem->show();
    pItem->setCompleter(new QCompleter(*mpItemNameList));
    outsourceInputList.emplace_back(pItem);
    SetLayout();
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
    outsourceInputList.clear();
    this->AddInputLineEdit();
    this->AddOutsourceLineEdit();
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
        if (result.first->level >2) continue;
        QLabel* pName = new QLabel(this);
        QLabel* pNum = new QLabel(this);
        QLabel* pWorkstation = new QLabel(this);
        {
            pName->setText(QString::fromStdString(result.first->name));
            pName->setMinimumHeight(15);
        }
        {
            ostringstream sout;
            sout<<result.second;
            pNum->setText(QString::fromStdString(sout.str()));
            pNum->setMinimumHeight(15);
        }
        if (result.first->level)
        {
            ostringstream sout;
            sout<<mpMaid->CalcWorkstationRequest(result);
            pWorkstation->setText(QString::fromStdString(sout.str()));
            pWorkstation->setMinimumHeight(15);
        }
        if (result.first->level >= 2)
        {
            int num = mpResultLayout[2]->count()/2;
            mpResultLayout[2]->addWidget(pName, num, 0);
            mpResultLayout[2]->addWidget(pNum, num, 1);
            mpResultLayout[2]->addWidget(pWorkstation, num, 2);
        }
        else
        {
            int num = mpResultLayout[result.first->level]->count()/2;
            mpResultLayout[result.first->level]->addWidget(pName, num, 0);
            mpResultLayout[result.first->level]->addWidget(pNum, num, 1);
            if (result.first->level)
            mpResultLayout[result.first->level]->addWidget(pWorkstation, num, 2);
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
    set<string> outsource;
    for (auto o : outsourceInputList)
    {
        outsource.insert(o->text().toStdString());
    }
    vector<ItemWithNum> requestList;
    for (auto request : requestInputList)
    {
        string name = request.first->text().toStdString();
        double num = request.second->text().toDouble();
        shared_ptr<Item> pItem;
        if (mpMaid->FindItem(name, pItem))
            requestList.emplace_back(pItem, num);
    }
    if (requestList.size())
    {
        this->ShowResult(mpMaid->CalcRequest(requestList, outsource));
    }
    else
    {
        this->ShowResult(mpMaid->RequestAllBuilding(outsource));
    }
    return;
}

void Widget::SwitchFormula()
{
    mpMaid->SwitchFormula();
    Cal();
    return;
}

void Widget::IncreaseProductionReagentStatusUpdate()
{
    mpMaid->setIncreaseProductionReagentlevel(mpQIncreaseProductionReagentSelector->checkedId());
}

void Widget::Init()
{
    mpMaid = std::make_shared<Maid>();
    mpMaid->Init();

    mpStartCalButton = make_shared<QPushButton>("开始计算",this);
    QObject::connect(mpStartCalButton.get(), &QPushButton::clicked, this, &Widget::Cal);

    mpResultLayout.resize(3);
    mpQScrollAreaVec.resize(3);
    for (int i = 0; i < 3; i++)
    {
        mpQScrollAreaVec[i] = make_shared<QScrollArea>(this);
        mpQScrollAreaVec[i]->resize(440, 800);
        mpQScrollAreaVec[i]->move(500+(2-i)*450, 50);
        QLabel* pWidget = new QLabel(this);
        pWidget->setFixedWidth(400);
        mpResultLayout[i] = make_shared<QGridLayout>(pWidget);
        mpResultLayout[i]->setSpacing(0);

        mpQScrollAreaVec[i]->setAlignment(Qt::AlignTop);
        mpQScrollAreaVec[i]->setWidget(pWidget);
        mpQScrollAreaVec[i]->show();
    }

    mpAddProductionButton = make_shared<QPushButton>("添加产物", this);
    QObject::connect(mpAddProductionButton.get(), &QPushButton::clicked, this, &Widget::AddInputLineEdit);

    mpAddOutsourceButton = make_shared<QPushButton>("添加外部输入产物", this);
    QObject::connect(mpAddOutsourceButton.get(), &QPushButton::clicked, this, &Widget::AddOutsourceLineEdit);

    mpSwitchFormulaButton = make_shared<QPushButton>("切换高/低级公式",this);
    QObject::connect(mpSwitchFormulaButton.get(), &QPushButton::clicked, this, &Widget::SwitchFormula);

    //{
    //    mpQIncreaseProductionReagentSelector = make_shared<QButtonGroup>(this);
    //    mpQIncreaseProductionReagent0 = make_shared<QRadioButton>("不使用增产剂",this);
    //    mpQIncreaseProductionReagent1 = make_shared<QRadioButton>("一级增产剂",this);
    //    mpQIncreaseProductionReagent2 = make_shared<QRadioButton>("二级增产剂",this);
    //    mpQIncreaseProductionReagent3 = make_shared<QRadioButton>("三级增产剂",this);
    //    mpQIncreaseProductionReagentSelector->addButton(mpQIncreaseProductionReagent0.get(), 0);
    //    mpQIncreaseProductionReagentSelector->addButton(mpQIncreaseProductionReagent1.get(), 1);
    //    mpQIncreaseProductionReagentSelector->addButton(mpQIncreaseProductionReagent2.get(), 2);
    //    mpQIncreaseProductionReagentSelector->addButton(mpQIncreaseProductionReagent3.get(), 3);
    //    mpQIncreaseProductionReagent0->setChecked(true);
    //    mpQIncreaseProductionReagent0->move(1700,50);
    //    mpQIncreaseProductionReagent1->move(1700,100);
    //    mpQIncreaseProductionReagent2->move(1700,150);
    //    mpQIncreaseProductionReagent3->move(1700,200);
    //    QObject::connect(mpQIncreaseProductionReagent0.get(), &QRadioButton::clicked, this, &Widget::IncreaseProductionReagentStatusUpdate);
    //    QObject::connect(mpQIncreaseProductionReagent0.get(), &QRadioButton::clicked, this, &Widget::IncreaseProductionReagentStatusUpdate);
    //    QObject::connect(mpQIncreaseProductionReagent0.get(), &QRadioButton::clicked, this, &Widget::IncreaseProductionReagentStatusUpdate);
    //    QObject::connect(mpQIncreaseProductionReagent0.get(), &QRadioButton::clicked, this, &Widget::IncreaseProductionReagentStatusUpdate);
    //}

    InitRequestList();
    return;
}
