#include "Maid.h"
#include <iostream>
using namespace std;
Maid::Maid()
{
    itemVec.clear();
    formulaVec.clear();
    itemMap.clear();
}

void Maid::InitItem()
{
    itemVec.emplace_back("铁矿");
    itemVec.emplace_back("铜矿");
    itemVec.emplace_back("石矿");
    itemVec.emplace_back("煤矿");
    itemVec.emplace_back("硅石");
    itemVec.emplace_back("钛石");
    itemVec.emplace_back("分形硅石");
    itemVec.emplace_back("水");
    itemVec.emplace_back("金伯利矿石");

    // 一级材料
    itemVec.emplace_back("铁块");
    itemVec.emplace_back("磁铁");
    itemVec.emplace_back("铜块");
    itemVec.emplace_back("石材");
    itemVec.emplace_back("玻璃");
    itemVec.emplace_back("硅石");
    itemVec.emplace_back("高能石墨");
    itemVec.emplace_back("高纯硅块");
    itemVec.emplace_back("钛块");
    itemVec.emplace_back("精炼油");

    // 二级材料
    itemVec.emplace_back("氢");
    itemVec.emplace_back("磁线圈");
    itemVec.emplace_back("晶格硅");
    itemVec.emplace_back("钛合金");
    itemVec.emplace_back("金刚石");
    itemVec.emplace_back("钢材");
    itemVec.emplace_back("电动机");
    itemVec.emplace_back("齿轮");
    itemVec.emplace_back("棱镜");
    itemVec.emplace_back("电磁涡轮");
    itemVec.emplace_back("电路板");
    itemVec.emplace_back("引力透镜");
    itemVec.emplace_back("奇异物质");
    itemVec.emplace_back("硫酸");
    itemVec.emplace_back("电浆激发器");
    itemVec.emplace_back("超级磁场环");
    itemVec.emplace_back("粒子带宽");
    itemVec.emplace_back("处理器");
    itemVec.emplace_back("微晶元件");
    itemVec.emplace_back("卡西米尔晶体");
    itemVec.emplace_back("粒子容器");
    itemVec.emplace_back("空间翘曲器");
    itemVec.emplace_back("光子合并器");
    itemVec.emplace_back("量子芯片");
    itemVec.emplace_back("石墨烯");
    itemVec.emplace_back("塑料");
    itemVec.emplace_back("增产剂 Mk.I");
    itemVec.emplace_back("增产剂 Mk.II");
    itemVec.emplace_back("增产剂 Mk.III");
    itemVec.emplace_back("液氢燃料棒");
    itemVec.emplace_back("氘核燃料棒");
    itemVec.emplace_back("钛晶石");
    itemVec.emplace_back("有机晶体");
    itemVec.emplace_back("重氢");
    itemVec.emplace_back("位面过滤器");
    itemVec.emplace_back("钛化玻璃");
    itemVec.emplace_back("碳纳米管");

    itemVec.emplace_back("电磁矩阵");
    itemVec.emplace_back("能量矩阵");
    itemVec.emplace_back("结构矩阵");
    itemVec.emplace_back("信息矩阵");
    itemVec.emplace_back("引力矩阵");

    for (int i = 0; i < itemVec.size();i++)
    {
        itemMap.insert({itemVec[i].name, make_shared<Item>(i, itemVec[i].name)});
    }
    return;
}

void Maid::InitFormula()
{
    formulaVec.emplace_back("铁块", 1, vector<string>{"铁矿"}, 60);
    formulaVec.emplace_back("铜块", 1, vector<string>{"铜矿"}, 60);
    formulaVec.emplace_back("高纯硅块", 1, vector<string>{"硅石", "硅石"}, 30);
    formulaVec.emplace_back("钛块", 1, vector<string>{"钛石", "钛石"}, 30);
    formulaVec.emplace_back("石材", 1, vector<string>{"石矿"}, 60);
    formulaVec.emplace_back("高能石墨", 1, vector<string>{"煤矿","煤矿"}, 30);
    formulaVec.emplace_back("磁铁", 1, vector<string>{"铁矿"}, 40);
    formulaVec.emplace_back("磁线圈", 2, vector<string>{"磁铁","磁铁","铜块"}, 60);
    formulaVec.emplace_back("晶格硅", 1, vector<string>{"高纯硅块"}, 30);
    formulaVec.emplace_back("钛合金", 4, vector<string>{"钛块", "钛块","钛块","钛块","钢材","钢材","钢材","钢材", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸"}, 5);
    formulaVec.emplace_back("玻璃", 1, vector<string>{"石矿","石矿"}, 30);
    formulaVec.emplace_back("金刚石", 1, vector<string>{"高能石墨"}, 30);
    formulaVec.emplace_back("钢材", 1, vector<string>{"铁块"}, 20);
    formulaVec.emplace_back("电动机", 1, vector<string>{"铁块","铁块", "齿轮", "磁线圈"}, 30);
    formulaVec.emplace_back("钛化玻璃", 2, vector<string>{"玻璃","玻璃","钛块","钛块","水","水"}, 12);
    formulaVec.emplace_back("棱镜", 2, vector<string>{"玻璃","玻璃","玻璃"}, 30);
    formulaVec.emplace_back("齿轮", 1, vector<string>{"铁块"}, 60);
    formulaVec.emplace_back("电磁涡轮", 1, vector<string>{"电动机","电动机","磁线圈","磁线圈"}, 30);
    formulaVec.emplace_back("硅石", 1, vector<string>{"石材","石材","石材","石材","石材","石材","石材","石材","石材","石材"}, 6);
    formulaVec.emplace_back("电路板", 2, vector<string>{"铁块","铁块","铜块"}, 60);
    formulaVec.emplace_back("引力透镜", 2, vector<string>{"金刚石","金刚石","金刚石","金刚石","奇异物质"}, 60);
    formulaVec.emplace_back("硫酸", 4, vector<string>{"精炼油","精炼油","精炼油","精炼油","石矿","石矿","石矿","石矿","石矿","石矿","石矿","石矿", "水", "水", "水", "水"}, 10);
    formulaVec.emplace_back("电浆激发器", 1, vector<string>{"磁线圈","磁线圈","磁线圈","磁线圈","棱镜","棱镜"}, 30);
    formulaVec.emplace_back("超级磁场环", 1, vector<string>{"电磁涡轮","电磁涡轮","磁铁","磁铁","磁铁","高能石墨"}, 20);
    formulaVec.emplace_back("粒子带宽", 1, vector<string>{"碳纳米管","碳纳米管","晶格硅","晶格硅","塑料"}, 7.5);
    formulaVec.emplace_back("处理器", 1, vector<string>{"电路板","电路板","微晶元件","微晶元件"}, 20);
    formulaVec.emplace_back("卡西米尔晶体", 1, vector<string>{"钛晶石","石墨烯","石墨烯","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢"}, 15);
    formulaVec.emplace_back("粒子容器", 1, vector<string>{"电磁涡轮","电磁涡轮","铜块","铜块","石墨烯","石墨烯"}, 15);
    formulaVec.emplace_back("空间翘曲器", 8, vector<string>{"引力透镜"}, 6);
    formulaVec.emplace_back("光子合并器", 1, vector<string>{"棱镜","棱镜","电路板"}, 20);
    formulaVec.emplace_back("微晶元件", 1, vector<string>{"高纯硅块","高纯硅块","铜块"}, 30);
    formulaVec.emplace_back("量子芯片", 1, vector<string>{"处理器","处理器","位面过滤器","位面过滤器"}, 10);
    formulaVec.emplace_back("石墨烯", 2, vector<string>{"高能石墨","高能石墨","高能石墨","硫酸"}, 20);
    formulaVec.emplace_back("塑料", 1, vector<string>{"精炼油","精炼油","高能石墨"}, 20);
    formulaVec.emplace_back("增产剂 Mk.I", 1, vector<string>{"煤矿"}, 120);
    formulaVec.emplace_back("增产剂 Mk.II", 1, vector<string>{"增产剂 Mk.I","增产剂 Mk.I","金刚石"}, 60);
    formulaVec.emplace_back("增产剂 Mk.III", 1, vector<string>{"增产剂 Mk.II","增产剂 Mk.II", "碳纳米管"}, 30);
    formulaVec.emplace_back("液氢燃料棒", 2, vector<string>{"钛块","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢"}, 10);
    formulaVec.emplace_back("氘核燃料棒", 2, vector<string>{"钛合金","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","重氢","超级磁场环"}, 5);
    formulaVec.emplace_back("有机晶体", 1, vector<string>{"塑料","塑料","精炼油","水"}, 10);
    formulaVec.emplace_back("钛晶石", 1, vector<string>{"有机晶体","钛块","钛块","钛块"}, 10);
    formulaVec.emplace_back("重氢", 5, vector<string>{"氢","氢","氢","氢","氢","氢","氢","氢","氢","氢"}, 24);
    formulaVec.emplace_back("位面过滤器", 1, vector<string>{"卡西米尔晶体","钛化玻璃","钛化玻璃"}, 5);
    formulaVec.emplace_back("碳纳米管", 2, vector<string>{"石墨烯","石墨烯","石墨烯","钛块"}, 15);
    formulaVec.emplace_back("奇异物质", 1, vector<string>{"粒子容器","粒子容器","铁块","铁块","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢"}, 7.5);

    formulaVec.emplace_back("电磁矩阵", 1, vector<string>{"磁线圈","电路板"}, 20);
    formulaVec.emplace_back("能量矩阵", 1, vector<string>{"高能石墨","高能石墨","氢","氢"}, 10);
    formulaVec.emplace_back("结构矩阵", 1, vector<string>{"金刚石","钛晶石"}, 7.5);
    formulaVec.emplace_back("信息矩阵", 1, vector<string>{"处理器","处理器","粒子宽带"}, 6);
    formulaVec.emplace_back("引力矩阵", 1, vector<string>{"引力透镜","量子芯片"}, 2.5);


    for (Formula formula : formulaVec)
    {
        itemMap.at(formula.production)->formula = formula;
    }
    //暂时不考虑所有的高效公式以及高级公式
    //等离子精炼先跳过
}
void Maid::CheckInit()
{
    for (auto entry : itemMap)
    {
        cout<<entry.first<<" ";
        for (auto material : entry.second->formula.materialList)
        {
            cout<<material<<" ";
        }
        cout<<endl;
    }
}

vector<ItemWithNum> Maid::CalcRequest(const vector<ItemWithNum>& requestList)
{
    vector<ItemWithNum> result;
    vector<ItemWithNum> needFormula;
    for (auto it : requestList)
    {
        result.emplace_back(it);
        needFormula.emplace_back(it);
    }
    while(1)
    {
        if (needFormula.empty()) break;
        vector<ItemWithNum> subItem;
        for (ItemWithNum it : needFormula)
        {
            if (it.first->formula.needFormula)
            {
                for (string item : it.first->formula.materialList)
                {
                    ItemWithNum sub = {itemMap.at(item), it.second / it.first->formula.productNum};
                    subItem.emplace_back(sub);
                    result.emplace_back(sub);
                }
            }
        }
        needFormula = subItem;
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
    for (Item item : itemVec)
    {
        itemNameList.emplace_back(item.name);
    }
    return itemNameList;
}

int Maid::Init()
{
    InitItem();
    InitFormula();
    //CheckInit();
    return 0;
}
