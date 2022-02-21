#ifndef MAID_H
#define MAID_H


#include <vector>
#include <map>
#include <memory>
#include "Item.h"
#include "Formula.h"
class Maid
{
public:
    int Init();
    Maid();

public:

    void InitFormula();
    void InitItem();
    void CheckInit();
    bool FindItem(const std::string&, std::shared_ptr<Item>&);
    std::vector<ItemWithNum> CalcRequest(const std::vector<ItemWithNum>&);

private:
    std::vector<Item> itemVec;
    std::vector<Formula> formulaVec;
    std::map<std::string, Item> itemMap;



};

#endif // MAID_H
