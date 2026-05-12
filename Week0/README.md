# Welcome to Resources Section of Week 0

#### Hi! Here are all your resources for week 0. 
##### Assignemnt 0: Github
1) Fork (just means that you create your copy of this at this particular commit) this Repo (term: means folder)  by clicking on the Fork button next to Watch Button and before the star button on the top right corner. 
2) You will be directed to make a new repo... Complete the process. Now, you must clone  (just a fancy word for copying the contents and history of the the repo) the repo to make a local instance of the repo... Enter this in terminal or command prompt:
	``` bash
	cd <any directory name name in which you want to create the repository (optional: else will be created in the root directory or the folder through which you opened the command prompt)>
	git clone https://github.com/ElectronicsClub-IITK/Cryptographically-Secure-Chaos-Engine.git
	```
	For future use: if you are cloning any remote (repository on web/github) just use the command  
	```bash
	git clone <url>
	```
	*Note: URL can be found by clicking on green code (make sure you are on https tab) button or just copying the link from the web browser*
3. This creates your own repo.. I want you guys now to complete a simple commit to be familiar with the command line. Lets write your name on a text file and upload it on github:
	1. make any file of your choice in the repository.
	2. For each branch there there is something called staging area.. In this you keep a part of working code, not worthy of being called a commit. 
	3. run the command 
		```bash
		git add .
		```
		This command is to "add" files into staging area. The "." mean add all the changed files to staging area.. If you need to add a/some particular file/s you execute like this:
		```bash
		git add file1.cpp file2.exe
		```
		This adds your files to staging area
	4. Now comes the thing "commit" (something that we fear irl!). The commit is an important part of the exercise. Commits create a snapshot of the repo you write something meaningful as the name of the commit.. You can use commits to revert back to a point in the history of the repo when it was working properly.
		```bash
		git commit -m <some meaningful message enclosed within double quotes>
		```   
		- we add "-m" in the command to let it know we want to write a 1-liner name to the commit (the name after -m). If you don't add "-m < message > ", github would prompt you to add a multiline comment. Please use 1-liner commits. 
4. Now that you have saved the changes in your own repo, you can "push" those changes to the web/remote repo. write 
	```
	git push origin main 
	``` 
	This would "push" your changes to **YOUR** remote repository (of which you have full access of).
	You can also simply use this for now:
	```bash
	git push
	```
5. Open github in your web browser, you would be able to see the changes in your repo. Now, if you want me to see the changes, you should click on contribute button. This will direct you to open the "Pull Request". It means that I will get a request to review your changes and add those changes to the main repo. Your work ends here.
6. Whenever making a new commit always "pull the changes". Assume there are many people working on the **main** repository, there would be some changes committed by other people that I have accepted. So, to make your own local repo be updated with those changes so there isn't any problem always pull the changes first. 
	-  Firstly, got to **YOUR** remote repository, click "sync fork". This would ensure all the changes in the main **(MY)** repo are reflected in your **remote** repository.   
	- Now go to the command line and run 
		```bash 
		git pull origin main
		```
		or simply
		```bash 
		git pull
		``` 
		for now
		This  would "pull" all changes from your remote repo to your local repo. If there are merge conflicts , tell me (i don't have enough time to write about them and how to solve them)

You would learn about branches, merging and remote urls in the session as well. This part was very important to learn. This is the reason i am documenting this. 
##### Assignemnt 1: 
[Crypto Assignment](https://cryptopals.com)
Explore this challenge the first 5-6 problems are really easy and the next problems may be difficult. Try them and make the submission by forking this repo
- the repo is somehing like this 
	|-week0
		|-set1
			|-challenge1.py
- Add the solutions of the challenges in the repo... and open a Pull Request (PR) and i will be able to see the changes. 
- If you have any problem in programming then refer to tutorials or just start it.. It is usually good to do some assignment or project instead of watching tutorials to learn a language. 
-   Hope you learn this assignment.

##### Assignment and resources 2: Kikad
*Will be uploaded Shortly*

##### Assignment and resources 3: digital electronics
*These are the same resources as electroverse, so if you have completed them just paste the same things as the submission*
[Electroverse Week 1 resources](https://docs.google.com/document/d/1u-MMxeZ7ST4k8zUW0lSkqGmXknFYt-Vs9YsOE0SgbUQ/edit?usp=sharing)
You can go through the resources till sequential digital circuits in the resources 
The assignemnt is given below 
[Assignment Digital Electronics](./DigitalAssignment.pdf)