#ifndef ITEM_H
#define ITEM_H
#include "Formula.h"
#include<string>
#include<vector>
#include<map>
#include<memory>

struct Item
{
    int id;
    std::string name;
    int level;
    Item(int _id, std::string _name)
    {
        id=_id;
        name=_name;
    }
    Item(std::string _name)
    {
        name=_name;
    }
    friend operator<(Item a, Item b)
    {
        return a.name < b.name;
    }
    Formula formula;
};

typedef std::shared_ptr<Item> ItemPtr;
typedef std::pair<ItemPtr, double> ItemWithNum;

#endif // ITEM_H
