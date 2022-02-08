#ifndef ITEM_H
#define ITEM_H
#include "Formula.h"
map<int, id> itemMap;
class Item
{
    int id;
    string name;
    int level;
    Item(int _id, string _name, int _level)
    {
        id=_id;
        name=_name;
        level=_level;
    }
    vector<Formula> formulas;
};

void initItemMap()
{
    itemMap.clear();

    //自然产物
    itemMap.insert({0, Item(0, "铁矿", 0)});
    itemMap.insert({1, Item(1, "铜矿", 0)});
    itemMap.insert({2, Item(2, "石矿", 0)});
    itemMap.insert({3, Item(3, "煤矿", 0)});
    itemMap.insert({4, Item(4, "硅矿", 0)});
    itemMap.insert({5, Item(5, "钛矿", 0)});

    //一级材料: 仅需自然产物即可获得的材料
    itemMap.insert({100,Item(100, "铁块", 1)});
    itemMap.insert({101,Item(101, "磁铁", 1)});
    itemMap.insert({102,Item(102, "铜块", 1)});
    itemMap.insert({103,Item(103, "石材", 1)});
    itemMap.insert({104,Item(104, "玻璃", 1)});
    itemMap.insert({105,Item(105, "硅石", 1)});
    itemMap.insert({106,Item(106, "高能石墨", 1)});
    itemMap.insert({107,Item(107, "高纯硅块", 1)});
    itemMap.insert({108,Item(108, "钛块", 1)});
    itemMap.insert({109,Item(109, "精炼油", 1)});

    //二级材料：需一级材料以上可以制作的材料
    itemMap.insert({200,Item(200, "齿轮", 2)});
    itemMap.insert({201,Item(201, "磁线圈", 2)});
    itemMap.insert({202,Item(202, "电路板", 2)});
    itemMap.insert({203,Item(203, "微晶元件", 2)});
    itemMap.insert({204,Item(204, "钢材", 2)});
    itemMap.insert({205,Item(205, "金刚石", 2)});
    itemMap.insert({206,Item(206, "晶格硅", 2)});
    itemMap.insert({207,Item(207, "钛晶石", 2)});
    itemMap.insert({208,Item(208, "塑料", 2)});
    itemMap.insert({209,Item(209, "钛化玻璃", 2)});
    itemMap.insert({210,Item(210, "石墨烯", 2)});
    itemMap.insert({211,Item(211, "液氢燃料棒", 2)});


    return;
}

#endif // ITEM_H
