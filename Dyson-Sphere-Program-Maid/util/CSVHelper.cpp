#include "CSVHelper.h"
#include <fstream>
using namespace std;

vector<string> CSVHelper::LineToVec(const std::string& str)
{
    vector<string> result;
    string temp="";
    for (int i =0;i<str.length();i++)
    {
        if (str[i] != ',') temp+=str[i];
        else
        {
            result.emplace_back(temp);
            temp="";
        }
    }
    result.emplace_back(temp);
    return result;
}

map<string, string> CSVHelper::LineToMap(const string& str, const vector<string>& headers)
{
    map<string, string> result;
    int cnt = 0;
    string temp="";
    for (int i =0;i<str.length();i++)
    {
        if (str[i] != ',') temp+=str[i];
        else
        {
            result[headers[cnt]] = temp;
            temp="";
            cnt++;
        }
    }
    result[headers[cnt]] = temp;
    return result;
}

CSVContent CSVHelper::LoadFromDisk(const std::string &path)
{
    CSVContent result;
    ifstream fin(path);
    string s;
    getline(fin,s);
    vector<string> headers = LineToVec(s);
    while(getline(fin, s))
    {
        result.emplace_back(LineToMap(s, headers));
    }
    return result;
}
