#ifndef CSVHELPER_H
#define CSVHELPER_H

#include <string>
#include <map>
#include <vector>
typedef std::vector<std::map<std::string, std::string>> CSVContent;

class CSVHelper
{
public:
    static CSVContent LoadFromDisk(const std::string& path);
    static std::map<std::string,std::string> LineToMap(const std::string& str, const std::vector<std::string>& headers);
    static std::vector<std::string> LineToVec(const std::string& str);
};

#endif // CSVHELPER_H
