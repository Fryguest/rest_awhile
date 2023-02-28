#include "Character.h"

void Character::updateAttribute() { return; }

int Character::GetMainAttribute()
{
    if (this->mainAttribute=="int") return this->inte;
    else if (this->mainAttribute=="str") return this->str;
    else if (this->mainAttribute=="dex") return this->dex;
    else return this->luk;
}

int Character::GetSubAttribute()
{
    if (this->subAttribute=="int") return this->inte;
    else if (this->subAttribute=="str") return this->str;
    else if (this->subAttribute=="dex") return this->dex;
    else return this->luk;
}

double Character::GetWeaponMultiplier()
{
    return 1.2;
}

int Character::GetAtkValue()
{
    if (this->mainAttribute=="int") return this->matk;
    else return this->atk;
}

int Character::CalcShownAttack()
{
    int mainAttribute = GetMainAttribute();
    int subAttribute = GetSubAttribute();
    int statsValue = mainAttribute * 4 + subAttribute;

    int actualUpperDamage = statsValue * GetAtkValue() * GetWeaponMultiplier() /100;

    return actualUpperDamage * (1 + this->damage / 100) * (1 + this->finalDamage / 100);
}

void Character::Init()
{
    this->mainAttribute="int";
    this->subAttribute="luk";
    this->inte = 42000;
    this->luk = 10000;
    this->matk = 4000;

    this->damage = 0;
    this->finalDamage = 0;
    return;
}
