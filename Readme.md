# 多文件合并
## 背景
集群提交的结果通常有很多个文件夹，
为了提升仿真的速度，
有时候会将多个迭代点拆分成不同的任务，
或者将相同的迭代点以不同种子的形式进行拆分。
因此在得到结果后需要进行合并，

本脚本的目的就是自动化合并的过程，
共存在以下几个目标：

- 数据文件夹来源需要整合
- 格式说明都是一样的，需要去重复
- 配置信息相同应该进行合并，配置不同的应分开
- 所有结果汇总入一个 txt 文件
- 相同迭代点的信息需要整合

## 思路

1. 遍历所有结果文件夹，按照配置信息生成 MD5码作为临时文件名，
那么相同配置信息可以输出至同一文件中。
2. 对每个临时文件内容进行排序，用 awk 命令进行数据合并和去重，然后关键字按需置顶。
3. 所有临时文件内容汇总，删除临时文件。

## 结果流程示意图
1. 原始文件
```
    *1.txt:*
    Source: tc_0
    Config: Polar
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       20
              -1 0.1     30       300
              -10 0.1     30       300

    *2.txt:*
    Source: tc_1
    Config: Polar
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       40
              -1 0.1     30       600
              -10 0.1     30       100

    *3.txt:*
    Source: tc_2
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       20
              -1 0.1     30       300
              -10 0.1     30       300

    *4.txt:*
    Source: tc_3
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       22
              -1 0.1     30       330
              -10 0.1     30       310
```

---

2. 文件合并
```
    *1.txt:*
    Source: tc_2
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       20
              -1 0.1     30       300
              -10 0.1     30       300

    Source: tc_3
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       22
              -1 0.1     30       330
              -10 0.1     30       310

    *2.txt:*
    Source: tc_0
    Config: Polar
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       20
              -1 0.1     30       300
              -10 0.1     30       300

    Source: tc_1
    Config: Polar
    Format: SNR BER ErrNum TotalNum
              0 0.5     10       40
              -1 0.1     30       600
              -10 0.1     30       100
```
---

3. 文件排序

```
    *1.txt:*
    Config: LDPC
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
    Format: SNR BER ErrNum TotalNum
    Source: tc_2
    Source: tc_3
              0 0.5     10       20
              0 0.5     10       22
              -1 0.1     30       300
              -1 0.1     30       330
              -10 0.1     30       300
              -10 0.1     30       310

    *2.txt:*
    Config: Polar
    Config: Polar
    Format: SNR BER ErrNum TotalNum
    Format: SNR BER ErrNum TotalNum
    Source: tc_0
    Source: tc_1
              0 0.5     10       20
              0 0.5     10       40
              -1 0.1     30       300
              -1 0.1     30       600
              -10 0.1     30       100
              -10 0.1     30       300 
```
---

4. 数据合并
```
    *1.txt:*
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
    Source: tc_2 tc_3
     0.0 0.476 20 42
     -1.0 0.095 60 630
     -10.0 0.098 60 610

    *2.txt:*
    Config: Polar
    Format: SNR BER ErrNum TotalNum
    Source: tc_0 tc_1
     0.0 0.333 20 60
     -1.0 0.067 60 900
     -10.0 0.150 60 400
```
---
5. 关键字排序和汇总
```
    *1.txt:*
    Config: LDPC
    Format: SNR BER ErrNum TotalNum
    Source: tc_2 tc_3
     0.0 0.476 20 42
     -1.0 0.095 60 630
     -10.0 0.098 60 610

    Config: Polar
    Format: SNR BER ErrNum TotalNum
    Source: tc_0 tc_1
     0.0 0.333 20 60
     -1.0 0.067 60 900
     -10.0 0.150 60 400
```
