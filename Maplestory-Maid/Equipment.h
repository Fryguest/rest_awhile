#ifndef EQUIPMENT_H
#define EQUIPMENT_H
#include <vector>
#include <map>

class EnhanceScroll
{

};

class StarFlame
{

};

class EquipmentBase
{
    std::string type;
    int level;
    int strength;
    int dexterity;
    int intelligence;
    int luckBase;
    int attack;
    int magicAttack;
    int damage;
    int bossDamage;
    int ignoreDefense;
    int enhanceLimit;

    void LoadFromJson();
};

class Equipment
{
    EquipmentBase base;
    StarFlame starFlame;
    int starForce;
    int potential;
    int additionPotential;
    std::vector<EnhanceScroll> enhanceScrollList;
    int calStarForceIntelligence();

};

class EquipmentSet
{
    std::map<std::string, Equipment> m;
    int getIntelligence();
    int getIntelligencePercent();
    int getIntelligenceAdd();
};


#endif // EQUIPMENT_H
