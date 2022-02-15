#ifndef MAID_H
#define MAID_H


#include <vector>
#include <map>
#include "Item.h"
#include "Formula.h"
class Maid
{
public:
    Init();
    Maid();

private:

    void InitFormula();
    void InitItem();
    void CheckInit();

private:
    std::vector<Item> itemVec;
    std::vector<Formula> formulaVec;
    std::map<std::string, Item> itemMap;

};

#endif // MAID_H
