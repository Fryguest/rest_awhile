#ifndef FORMULA_H
#define FORMULA_H

#include<vector>
#include<string>

struct Formula
{
    std::string production;//产物Id， 当前不考虑多产物的情况
    int productNum;//每次生产的数量
    std::vector<std::string> materialList; //材料列表
    double dpm; //每分钟制作次数
    bool needFormula; //是否需要配方
    Formula(std::string _production, int _productNum, std::vector<std::string> _materialList, double _dpm)
    {
        production = _production;
        productNum = _productNum;
        materialList = _materialList;
        dpm = _dpm;
        needFormula = true;
    }
    Formula()
    {
        needFormula = false;
    }
};

#endif // FORMULA_H
