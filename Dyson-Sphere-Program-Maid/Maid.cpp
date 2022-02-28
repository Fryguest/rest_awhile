#include "Maid.h"
#include "util/CSVHelper.h"
#include <queue>
#include <iostream>
using namespace std;

vector<ItemWithNum> Maid::CalcRequest(const vector<ItemWithNum>& requestList)
{
    vector<ItemWithNum> result;
    queue<ItemWithNum> q;
    for (auto it : requestList) q.push(it);
    while (!q.empty())
    {
        ItemWithNum item = q.front(); q.pop();
        cout<<item.first->name << " " << item.second<<endl;

        result.emplace_back(item);
        if (item.first->level > 0)
        {
            auto pFormula = item.first->pFormula;
            for (ItemWithNum material : pFormula->materialList)
            {
                q.emplace(material.first, item.second * material.second / pFormula->production.second);
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

int Maid::Init()
{
    CSVContent content = CSVHelper::LoadFromDisk("./Item.csv");
    cout<<content.size()<<endl;
    for (auto line : content)
    {
        itemMap[line.at("名称")] = make_shared<Item>(line.at("名称"));
    }
    for (auto line : content)
    {
        itemMap[line.at("名称")]->LoadFromMap(line, itemMap);
    }
    return 0;
}
