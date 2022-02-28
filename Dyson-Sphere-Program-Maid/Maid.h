#ifndef MAID_H
#define MAID_H

#include <vector>
#include <map>
#include <string>
#include <memory>
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
    std::vector<ItemWithNum> CalcRequest(const std::vector<ItemWithNum>&);

private:
    std::map<std::string, std::shared_ptr<Item>> itemMap;

};

#endif // MAID_H
