---
title: LaTex 模板
date: 2022-01-24 11:53:31
mathjax: true
categories:
- LaTeX
tags:
- LaTeX
cover: https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/LaTeX_logo.svg/1200px-LaTeX_logo.svg.png
---

# LaTeX 模板

因为LaTeX在完成论文等工作时排版比较容易，但是入门难度比较高，在入门LaTeX约一年后，我准备整理一下所获取的LaTeX信息，构建属于自己的模板。

<!-- more -->

模板采用分文件的方式，使作者更专注于自己的书写内容，为更好的支持中文，使用`xelatex`编译，目前已经测试通过，除却LaTeX的基础功能之外，本模板包括的功能如下：

- 添加`pdf`作为封面
- 参考文献功能
- ...

# 模板文件

模板文件如下所示，可以下载使用：

## main

`main.tex`是主文件，如下：

```LaTex
% !TEX program = xelatex
\documentclass[UTF8, a4paper, 12pt]{ctexart}
\usepackage{fancyhdr}
\ctexset{section = {format={\Large\bfseries}}}

\usepackage[left=1in, right=1in, top=1in, bottom=1in]{geometry}
\usepackage{listings}
\usepackage{graphicx}
\usepackage{subcaption}
\usepackage{subfiles}
\usepackage{fontspec}
\usepackage[hidelinks]{hyperref}
\usepackage{cite}
\usepackage{url}
\usepackage{enumitem}
\usepackage{ulem}
\usepackage{pdfpages}

\pagestyle{fancy}
% \fancyhf{}
% \fancyhead[R]{\leftmark}
% \fancyhead[L]{\rightmark}
\setlength{\headheight}{14.5pt}

\setlength{\arrayrulewidth}{0.5mm}
\setlength{\tabcolsep}{18pt}
\renewcommand{\arraystretch}{1.5}

\graphicspath{ {./img/} }
\input{color.tex}
\input{style.tex}

\lstset{style=mystyle}

%==================================%
\title{\textbf{\LaTeX 模板} \\ {\small 简单的\LaTeX 模板}}
\author{Author}
\date{\today}

\begin{document}
% add custom cover
% \includepdf[pages={1}]{cover.pdf}
\maketitle
\tableofcontents
\newpage

\section{Part 1}
\subfile{part.tex}

% \bibliographystyle{unsrt}
% \bibliography{refs}
\end{document}
```

## color

`color.tex`是关于颜色的定义，在诸如定义代码样式时可以使用：

```latex
\usepackage{xcolor}

\definecolor{codegreen}{rgb}{0,0.6,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolour}{rgb}{0.95,0.95,0.92}
\definecolor{seabornBlue}{RGB}{76,114,176}
% colors
\definecolor{white}{rgb}{1,1,1}
\definecolor{black}{rgb}{0,0,0}
\definecolor{middlegray}{rgb}{0.5,0.5,0.5}
\definecolor{lightgray}{rgb}{.95,.95,.95}
\definecolor{arsenic}{rgb}{0.23, 0.27, 0.29}
\definecolor{arsenicLight}{rgb}{0.20, 0.20, 0.20}
\definecolor{darkgray}{rgb}{.4,.4,.4}
\definecolor{purple}{rgb}{0.65, 0.12, 0.82}
\definecolor{orange}{rgb}{0.8,0.3,0.3}
\definecolor{yac}{rgb}{0.6,0.6,0.1}
\definecolor{green}{rgb}{.2,0.6,0.3}
\definecolor{azure}{rgb}{0.0, 0.5, 1.0}
\definecolor{editorGray}{rgb}{0.95, 0.95, 0.95}
\definecolor{editorOcher}{rgb}{1, 0.5, 0}
\definecolor{editorGreen}{rgb}{0, 0.5, 0}
\definecolor{orange}{rgb}{1,0.45,0.13}		
\definecolor{olive}{rgb}{0.17,0.59,0.20}
\definecolor{brown}{rgb}{0.69,0.31,0.31}
\definecolor{purple}{rgb}{0.38,0.18,0.81}
\definecolor{lightblue}{rgb}{0.1,0.57,0.7}
\definecolor{lightred}{rgb}{1,0.4,0.5}

\definecolor{vscodered}{HTML}{E53935}
\definecolor{vscodelightred}{HTML}{EF5350}
\definecolor{vscodeblue}{HTML}{1565C0}
\definecolor{vscodegreen}{HTML}{66BB6A}

\definecolor{lightblack}{HTML}{212121}
\definecolor{darkraspberry}{rgb}{0.53, 0.15, 0.34}

% blue hues
\definecolor{bleudefrance}{rgb}{0.19, 0.55, 0.91}
\definecolor{brandeisblue}{rgb}{0.0, 0.44, 1.0}
\definecolor{blue(ncs)}{rgb}{0.0, 0.53, 0.74}
\definecolor{coolblack}{rgb}{0.0, 0.18, 0.39}

% red hues
\definecolor{coralred}{rgb}{1.0, 0.25, 0.25}
\definecolor{darkred}{rgb}{0.55, 0.0, 0.0}
```

## style

部分样式的定义：

```latex
% define some style

% code style
\lstdefinestyle{mystyle}{
	language=C++,
    backgroundcolor=\color{backcolour},   
    commentstyle=\color{codegreen}\textit,
    keywordstyle=\color{magenta}\textbf,
    numberstyle=\scriptsize\fontspec{Consolas}\color{codegray},
    stringstyle=\color{codepurple},
	identifierstyle=\color{vscodeblue},
    basicstyle=\scriptsize\fontspec{Consolas},
    escapeinside=``,
    breakatwhitespace=false,         
    breaklines=true,                 
    captionpos=b,                    
    keepspaces=true,                 
    numbers=left,                    
    numbersep=-13pt,                  
    showspaces=false,                
    showstringspaces=false,
    showtabs=false,                  
    tabsize=4
}
```

## part

章节分文件，为更好的组织文章：

```latex
\documentclass[main.tex]{subfiles}

\begin{document}
\section{Part 2}
This is part 2.

\end{document}
```
