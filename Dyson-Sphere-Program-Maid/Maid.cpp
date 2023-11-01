#include "Maid.h"
#include "util/CSVHelper.h"
#include <queue>
#include <iostream>
using namespace std;

vector<ItemWithNum> Maid::RequestAllBuilding(const set<string>& outsource)
{
    vector<ItemWithNum> requestList;
    for (auto o : itemMap)
    {
        if (o.second->level == 3)
        {
            auto& pFormula = o.second->pFormula;
            requestList.emplace_back(o.second, pFormula->production.second * 60 * 1.5 / pFormula -> timeCost);
        }
    }
    return CalcRequest(requestList, outsource);
}

double Maid::CalcWorkstationRequest(const ItemWithNum& request)
{
    if (request.first->pFormula == nullptr) return 0;
    auto pFormula = request.first->pFormula;

    double temp = 1;
    if (pFormula->place == "制造台") temp = 1.5;
    else if (pFormula->place == "科研设备") temp = 1;
    else if (pFormula->place == "冶炼设备") temp = 2;
    else if (pFormula->place == "化工设备") temp = 2;
    else if (pFormula->place == "粒子对撞机") temp = 1;
    else if (pFormula->place == "精炼设备") temp = 1;

//    if (pFormula->place == "制造台") temp = 0.75;
//    else if (pFormula->place == "科研设备") temp = 1;
//    else if (pFormula->place == "冶炼设备") temp = 1;
//    else if (pFormula->place == "化工设备") temp = 1;
//    else if (pFormula->place == "粒子对撞机") temp = 1;
//    else if (pFormula->place == "精炼设备") temp = 1;

    return request.second * pFormula->timeCost / (60 * pFormula->productionSpeedup * temp * pFormula->production.second * pFormula->productionBoost);
}

vector<ItemWithNum> Maid::CalcRequest(const vector<ItemWithNum>& requestList, const set<string>& outsource)
{
    vector<ItemWithNum> result;
    queue<ItemWithNum> q;
    for (auto it : requestList) q.push(it);
    while (!q.empty())
    {
        ItemWithNum item = q.front(); q.pop();
        if (outsource.find(item.first->name) != outsource.end()) continue;
        result.emplace_back(item);
        if (item.first->level > 0)
        {
            auto pFormula = item.first->pFormula;
            for (ItemWithNum material : pFormula->materialList)
            {
                q.emplace(material.first, item.second * material.second / pFormula->production.second / pFormula->productionBoost);
            }
        }
    }
    for (int i = 0; i < result.size(); i++)
    {
        for (int j = 0; j < i; j++)
        {
            if (result[i].first->name == result[j].first->name)
            {
                result[j].second += result[i].second;
                result.erase(result.begin() + i);
                i--;
                break;
            }
        }
    }
    return result;
}

bool Maid::FindItem(const string& name, shared_ptr<Item>& pItem)
{
    if (itemMap.find(name) == itemMap.end()) return false;
    pItem = itemMap.at(name);
    return true;
}

vector<string> Maid::GetItemNameList()
{
    vector<string> itemNameList;
    for (auto o : itemMap)
    {
        itemNameList.emplace_back(o.first);
    }
    return itemNameList;
}

void Maid::SwitchFormula()
{
    if (useAdvancedFormula == false)
    {
        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("晶格硅"), 2);
            pFormula->materialList.emplace_back(itemMap.at("分形硅石"), 1);
            pFormula->place = "制造台";
            pFormula->timeCost = 1.5;
            itemMap.at("晶格硅")->pFormula = pFormula;
            itemMap.at("晶格硅")->level = 1;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("金刚石"), 2);
            pFormula->materialList.emplace_back(itemMap.at("金伯利矿石"), 1);
            pFormula->place = "冶炼设备";
            pFormula->timeCost = 1.5;
            itemMap.at("金刚石")->pFormula = pFormula;
            itemMap.at("金刚石")->level = 1;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("石墨烯"), 2);
            pFormula->materialList.emplace_back(itemMap.at("可燃冰"), 2);
            pFormula->place = "化工厂";
            pFormula->timeCost = 2;
            pFormula->exProduction = make_pair(itemMap.at("氢"), 1);
            itemMap.at("石墨烯")->pFormula = pFormula;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("碳纳米管"), 2);
            pFormula->materialList.emplace_back(itemMap.at("刺笋结晶"), 6);
            pFormula->place = "化工厂";
            pFormula->timeCost = 4;
            itemMap.at("碳纳米管")->pFormula = pFormula;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("光子合并器"), 1);
            pFormula->materialList.emplace_back(itemMap.at("光栅石"), 1);
            pFormula->materialList.emplace_back(itemMap.at("电路板"), 1);
            pFormula->place = "制造台";
            pFormula->timeCost = 3;
            itemMap.at("光子合并器")->pFormula = pFormula;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("卡西米尔晶体"), 1);
            pFormula->materialList.emplace_back(itemMap.at("光栅石"), 4);
            pFormula->materialList.emplace_back(itemMap.at("石墨烯"), 2);
            pFormula->materialList.emplace_back(itemMap.at("氢"), 12);
            pFormula->place = "制造台";
            pFormula->timeCost = 4;
            itemMap.at("卡西米尔晶体")->pFormula = pFormula;
        }

        {
            shared_ptr<Formula> pFormula = make_shared<Formula>();
            pFormula->production = make_pair(itemMap.at("粒子容器"), 1);
            pFormula->materialList.emplace_back(itemMap.at("单极磁石"), 10);
            pFormula->materialList.emplace_back(itemMap.at("铜块"), 2);
            pFormula->place = "制造台";
            pFormula->timeCost = 4;
            itemMap.at("粒子容器")->pFormula = pFormula;
        }


        {
            itemMap.at("有机晶体")->level = 0;
            itemMap.at("有机晶体")->pFormula = nullptr;
        }

        {
            itemMap.at("硫酸")->level = 0;
            itemMap.at("硫酸")->pFormula = nullptr;
        }

        {
            itemMap.at("重氢")->level = 0;
            itemMap.at("重氢")->pFormula = nullptr;
        }
        useAdvancedFormula = true;

    }
    else
    {
        Init();
        useAdvancedFormula = false;
    }
    return;
}

int Maid::Init()
{
    CSVContent content = CSVHelper::LoadFromDisk("./Item.csv");
    //cout<<content.size()<<endl;
    for (auto line : content)
    {
        itemMap[line.at("名称")] = make_shared<Item>(line.at("名称"));
    }
    for (auto line : content)
    {
        itemMap[line.at("名称")]->LoadFromMap(line, itemMap);
    }
    useAdvancedFormula = false;
    increaseProductionReagentLevel = 0;
    return 0;
}
