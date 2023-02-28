#ifndef CHARACTER_H
#define CHARACTER_H
#include "Job.h"

class Character
{
public:
    void Init();
    int CalcShownAttack();

    void SetStr(int str) {this->str=str;}
    void SetInt(int inte) {this->inte=inte;}
    void SetDex(int dex) {this->dex=dex;}
    void SetLuk(int luk) {this->luk=luk;}

    void SetAtk(int atk) {this->atk=atk;}
    void SetMatk(int matk) {this->matk=matk;}

    void SetDamage(int damage) {this->damage=damage;}
    void SetFinalDamage(int finalDamage) {this->finalDamage=finalDamage;}

private:
    int level;
    Job job;

    int str;
    int inte;
    int dex;
    int luk;

    int atk;
    int matk;

    int damage;
    int finalDamage;

    std::string mainAttribute;
    std::string subAttribute;

    void updateAttribute();



    int GetMainAttribute();
    int GetSubAttribute();
    double GetWeaponMultiplier();
    int GetAtkValue();


};

#endif // CHARACTER_H
