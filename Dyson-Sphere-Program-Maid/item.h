#ifndef ITEM_H
#define ITEM_H
#include "Formula.h"
#include<string>
#include<vector>
#include<map>

struct Item
{
    int id;
    std::string name;
    int level;
    Item(int _id, std::string _name, int _level)
    {
        id=_id;
        name=_name;
        level=_level;
    }
    std::vector<Formula> formulas;
};

void initItemMap(std::map<std::string, Item>& itemMap)
{
    std::vector<std::vector<std::string>> itemVec(3, std::vector<std::string>{});
    itemVec[0].push_back("铁矿");
    itemVec[0].push_back("铜矿");
    itemVec[0].push_back("石矿");
    itemVec[0].push_back("煤矿");
    itemVec[0].push_back("硅石");
    itemVec[0].push_back("钛石");
    itemVec[0].push_back("分形硅石");
    itemVec[0].push_back("水");
    itemVec[0].push_back("金伯利矿石");

    itemVec[1].push_back("铁块");
    itemVec[1].push_back("磁铁");
    itemVec[1].push_back("铜块");
    itemVec[1].push_back("石材");
    itemVec[1].push_back("玻璃");
    itemVec[1].push_back("硅石");
    itemVec[1].push_back("高能石墨");
    itemVec[1].push_back("高纯硅块");
    itemVec[1].push_back("钛块");
    itemVec[1].push_back("精炼油");

    //TODO 添加二级材料
    itemVec[2].push_back("磁线圈");
    itemVec[2].push_back("晶格硅");
    itemVec[2].push_back("钛合金");
    itemVec[2].push_back("金刚石");
    itemVec[2].push_back("钢材");
    itemVec[2].push_back("电动机");
    itemVec[2].push_back("齿轮");
    itemVec[2].push_back("棱镜");
    itemVec[2].push_back("电磁涡轮");
    itemVec[2].push_back("电路板");
    itemVec[2].push_back("引力透镜");
    itemVec[2].push_back("奇异物质");
    itemVec[2].push_back("硫酸");
    itemVec[2].push_back("电浆激发器");
    itemVec[2].push_back("超级磁场环");
    itemVec[2].push_back("粒子带宽");
    itemVec[2].push_back("处理器");
    itemVec[2].push_back("微晶元件");
    itemVec[2].push_back("卡西米尔晶体");
    itemVec[2].push_back("粒子容器");

    itemVec[2].push_back("空间翘曲器");
    itemVec[2].push_back("光子合并器");


    itemMap.clear();
    for (int level = 0; level < itemVec.size(); level++)
    {
        for (int i = 0; i < itemVec[level].size(); i++)
        {
            itemMap.insert({itemVec[level][i], Item(i + level * 100, itemVec[level][i], level)});
        }
    }
    return;
}

void initFormulaList(std::map<int, Item>& itemMap)
{
    std::vecetor<Formula> formulas;

    formulas.push_back(Formula("铁块", 1, std::vector<std::string>{"铁矿"}, 60));
    formulas.push_back(Formula("铜块", 1, std::vector<std::string>{"铜矿"}, 60));
    formulas.push_back(Formula("高纯硅块", 1, std::vector<std::string>{"硅石", "硅石"}, 30));
    formulas.push_back(Formula("钛块", 1, std::vector<std::string>{"钛石", "钛石"}, 30));
    formulas.push_back(Formula("石材", 1, std::vector<std::string>{"石矿"}, 60));
    formulas.push_back(Formula("高能石墨", 1, std::vector<std::string>{"煤矿","煤矿"}, 30));
    formulas.push_back(Formula("磁铁", 1, std::vector<std::string>{"铁矿"}, 40));
    formulas.push_back(Formula("磁线圈", 2, std::vector<std::string>{"磁铁","磁铁","铜块"}, 60));
    formulas.push_back(Formula("晶格硅", 1, std::vector<std::string>{"高纯硅块"}, 30));
    formulas.push_back(Formula("钛合金", 4, std::vector<std::string>{"钛块", "钛块","钛块","钛块","钢材","钢材","钢材","钢材", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸", "硫酸"}, 5));
    formulas.push_back(Formula("玻璃", 1, std::vector<std::string>{"石矿","石矿"}, 30));
    formulas.push_back(Formula("金刚石", 1, std::vector<std::string>{"高能石墨"}, 30));
    formulas.push_back(Formula("钢材", 1, std::vector<std::string>{"铁块"}, 20));
    formulas.push_back(Formula("电动机", 1, std::vector<std::string>{"铁块","铁块", "齿轮", "磁线圈"}, 30));
    formulas.push_back(Formula("晶格硅", 2, std::vector<std::string>{"分形硅石"}, 40));
    formulas.push_back(Formula("钛化玻璃", 2, std::vector<std::string>{"玻璃","玻璃","钛块","钛块","水","水"}, 12));
    formulas.push_back(Formula("棱镜", 2, std::vector<std::string>{"玻璃","玻璃","玻璃"}, 30));
    formulas.push_back(Formula("金刚石", 2, std::vector<std::string>{"金伯利矿石"}, 40));
    formulas.push_back(Formula("齿轮", 1, std::vector<std::string>{"铁块"}, 60));
    formulas.push_back(Formula("电磁涡轮", 1, std::vector<std::string>{"电动机","电动机","磁线圈","磁线圈"}, 30));
    formulas.push_back(Formula("硅石", 1, std::vector<std::string>{"石材","石材","石材","石材","石材","石材","石材","石材","石材","石材"}, 6));
    formulas.push_back(Formula("电路板", 2, std::vector<std::string>{"铁块","铁块","铜块"}, 60));
    formulas.push_back(Formula("引力透镜", 2, std::vector<std::string>{"金刚石","金刚石","金刚石","金刚石","奇异物质"}, 60));
    formulas.push_back(Formula("硫酸", 4, std::vector<std::string>{"精炼油","精炼油","精炼油","精炼油","石矿","石矿","石矿","石矿","石矿","石矿","石矿","石矿", "水", "水", "水", "水"}, 10));


    formulas.push_back(Formula("电浆激发器", 1, std::vector<std::string>{"磁线圈","磁线圈","磁线圈","磁线圈","棱镜","棱镜"}, 30));
    formulas.push_back(Formula("超级磁场环", 1, std::vector<std::string>{"电磁涡轮","电磁涡轮","磁铁","磁铁","磁铁","高能石墨"}, 20));
    formulas.push_back(Formula("粒子带宽", 1, std::vector<std::string>{"碳纳米管","碳纳米管","晶格硅","晶格硅","塑料"}, 60.0/8));
    formulas.push_back(Formula("处理器", 1, std::vector<std::string>{"电路板","电路板","微晶元件","微晶元件"}, 20));
    formulas.push_back(Formula("卡西米尔晶体", 1, std::vector<std::string>{"钛晶石","石墨烯","石墨烯","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢","氢"}, 15));
    formulas.push_back(Formula("粒子容器", 1, std::vector<std::string>{"电磁涡轮","电磁涡轮","铜块","铜块","石墨烯","石墨烯"}, 15));
    formulas.push_back(Formula("空间翘曲器", 8, std::vector<std::string>{"引力透镜"}, 6));
    formulas.push_back(Formula("光子合并器", 1, std::vector<std::string>{"棱镜","棱镜","电路板"}, 20));




}

#endif // ITEM_H
