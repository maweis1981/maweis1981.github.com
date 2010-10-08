--- 
wordpress_id: 488
layout: post
title: benchmark for tokyocacabinet
wordpress_url: http://maweis.com/?p=488
---
<pre lang="c" >
#include <tcutil.h>
#include <tcadb.h>
#include <tcbdb.h>
#include <tctdb.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>

// gcc -o tokyocabinet_test -ltokyocabinet -lbz2 -lz -lpthread -lm -lc -L/usr/local/lib -L/opt/local/lib -I/usr/local/include tokyocabinet_test.c 


int main(int argc, char **argv){
	const char *dbname;
	dbname = "/Users/peter/tcttest.tct";
	printf(dbname);
	printf("\n");
	TCADB *adb = tcadbnew();
	if(!tcadbopen(adb, dbname)){
	 	fprintf(stderr, "open error: %s\n", dbname);
	}
	
	const int max_line = 1000000;
	int i;
	
	const char *key;
	const char *value;
	
	char tempstr[10];


	clock_t start, end;
	long elapsed;

	start = clock();
		
	for(i = 0;i <= max_line; i ++)
	{
		/* code */
		sprintf(tempstr, "%d", i);
		key = tempstr;
		sprintf(tempstr, "%d", i);
		value = tempstr;
		tcadbput2(adb,key,value);
	}
		
	end = clock();
	elapsed = ((end - start) * 1000 )/ CLOCKS_PER_SEC;
	printf("TOTAL TIME = %ld\n",elapsed);
	  
	if(!tcadbclose(adb)){
	    fprintf(stderr, "close error:");
		return 0;
	}
	tcadbdel(adb);
	return 0;
}
</pre>
