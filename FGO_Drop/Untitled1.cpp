#include<bits/stdc++.h>
using namespace std;

vector<string> getCSVLine(const string& str)
{
	vector<string> v;
	string temp="";
    for (int i=0;i<str.length();i++)
    {
        if (str[i]!=',') temp+=str[i];
        else
        {
        	v.push_back(temp); 
            temp="";
        }
    }
    v.push_back(temp);
    return v;
}

struct Item
{
	string name; //名称 
	double value; // 价值 
	double coefficient; // 需求系数 
	Item(){}
	Item(const string& str)
	{
		vector<string> v=getCSVLine(str);
	    name=v[0];
	    value=stod(v[1]);
	    coefficient=stod(v[2]);
	}
};
struct Stage
{
	string name;
	vector<pair<Item, double>> drop;
	int cost;
	double value;
	Stage(){}
	Stage(const string& str)
	{
		vector<string> v=getCSVLine(str);
		name=v[0];
		cost=stod(v[1]);
	}
	void calValue()
	{
		value = 0;
		for (pair<Item, double> o : drop)
		{
			value += o.first.value * o.second * o.first.coefficient;
		}
	}
	void add(Item item, double dropRate)
	{
		cout<<name<<" " <<item.name<< " " << dropRate<<endl;
		pair<Item, double> p(item, dropRate);
		drop.push_back(p);
	}
};

void readDrop(map<string,Stage>& stageMap, map<string,Item>& itemMap)
{
	ifstream fin("drop.csv");
	string s;
	getline(fin, s);
	while (getline(fin, s))
	{
		vector<string>v=getCSVLine(s);
		string stageName=v[0];
		string itemName=v[1];
		cout << (itemMap.find(itemName) == itemMap.end()? "NO" : "YES") << " " << itemName<<endl;
		double dropRate=stod(v[2]);
		cout<<"readDrop: " << itemMap[itemName].name << " " << itemMap[itemName].value<<endl;
		stageMap.at(stageName).add(itemMap[itemName], dropRate);
	}
	fin.close();
	
}

void readItem(map<string, Item>& itemMap)
{
	ifstream fin("item.csv");
	string s;
	getline(fin, s);
	while (getline(fin, s))
	{
		Item temp(s);
		itemMap[temp.name]=temp;
	}
	fin.close();
}

void readStage(map<string, Stage>& stageMap)
{
	ifstream fin("stage.csv");
	string s;
	getline(fin, s);
	while (getline(fin, s))
	{
		Stage temp(s);
		stageMap[temp.name]=temp;
	}
	fin.close();
}

bool comp(Stage a, Stage b)
{
	return a.value>b.value;
}

int main()
{
	map<string, Stage> stageMap;
	map<string, Item> itemMap;
	readItem(itemMap);
	readStage(stageMap);
	readDrop(stageMap, itemMap);
	vector<Stage>v;
	for (auto it=stageMap.begin(); it!=stageMap.end();it++)
	{
		it->second.calValue();
		v.push_back(it->second);
	}
	sort(v.begin(), v.end(), comp);
	for (int i=0;i<10;i++)
	{
		cout<<v[i].name<<" "<<v[i].value<<endl;
	}
	return 0;
}
