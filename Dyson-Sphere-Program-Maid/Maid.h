#ifndef MAID_H
#define MAID_H

#include <vector>
#include <map>
#include <string>
#include <memory>
#include <set>
#include "Item.h"

class Maid
{

public:
    int Init();
    void InitFormula();
    void InitItem();
    void CheckInit();
    bool FindItem(const std::string&, std::shared_ptr<Item>&);
    std::vector<std::string> GetItemNameList();
    std::vector<ItemWithNum> CalcRequest(const std::vector<ItemWithNum>&, const std::set<std::string>&);
    std::vector<ItemWithNum> RequestAllBuilding(const std::set<std::string>&);
    double CalcWorkstationRequest(const ItemWithNum& request);
    void SwitchFormula();

public:
    void setIncreaseProductionReagentlevel(const int& level){this->increaseProductionReagentLevel = level;}

private:
    std::map<std::string, std::shared_ptr<Item>> itemMap;
    bool useAdvancedFormula;
    int increaseProductionReagentLevel;

};

#endif // MAID_H
