#ifndef ITEM_H
#define ITEM_H
#include<string>
#include<vector>
#include<map>
#include<memory>

struct Item;
typedef std::shared_ptr<Item> ItemPtr;
typedef std::pair<ItemPtr, double> ItemWithNum;

struct Formula
{
public:
    ItemWithNum production; //产物
    ItemWithNum exProduction; //副产物
    std::string place;
    std::vector<ItemWithNum> materialList; //材料列表
    double timeCost; //制作耗时
public:
    Formula(){}
    void LoadFromMap(const std::map<std::string, std::string>& input, const std::map<std::string, ItemPtr>& itemMap)
    {
        production.first = itemMap.at(input.at("名称"));
        production.second = std::stoi(input.at("产量"));
        exProduction.first = itemMap.at(input.at("副产物名称"));
        exProduction.second = std::stoi(input.at("副产物产量"));
        place = input.at("配方场所");
        timeCost = std::stod(input.at("配方耗时"));
        materialList.clear();
        for (int i=1;i<=6;i++)
        {
            std::string materialName = input.at("材料" + std::to_string(i));
            int materialNum = std::stoi(input.at("数量" + std::to_string(i)));
            if (itemMap.find(materialName) == itemMap.end()) break;
            materialList.emplace_back(itemMap.at(materialName), materialNum);
        }
    }
};

struct Item
{

public:
    int id;
    std::string name;
    int level;
    std::shared_ptr<Formula> pFormula;

public:
    Item() {}
    Item(std::string _name) { name=_name; }
    friend operator<(Item a, Item b) { return a.name < b.name; }
    void LoadFromMap(const std::map<std::string, std::string>& input, const std::map<std::string, ItemPtr>& itemMap)
    {
        id = std::stoi(input.at("Id"));
        name = input.at("名称");
        level = std::stoi(input.at("等级"));
        if (level)
        {
            pFormula = std::make_shared<Formula>();
            pFormula->LoadFromMap(input, itemMap);
        }
        return;
    }
};

#endif // ITEM_H
