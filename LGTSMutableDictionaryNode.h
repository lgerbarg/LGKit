/*
  Copyright 2009 Louis Gerbarg
 
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
 
       http://www.apache.org/licenses/LICENSE-2.0
 
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/*
 *  LGTSMutableDictionaryNode.h
 *  LGTSMutableDictionary
 *
 *  Created by Louis Gerbarg on 5/16/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

typedef struct LGTSMutableDictionaryNode LGTSMutableDictionaryNode;
struct LGTSMutableDictionaryNode{
	__strong id key;
	__strong id data;
	NSUInteger count;
	LGTSMutableDictionaryNode *left;
	LGTSMutableDictionaryNode *right;
	volatile int32_t refCount;
	
	uint8_t color:1;
	uint8_t writeable:1;
};

NSUInteger LGTSMDN_Count(LGTSMutableDictionaryNode *node);

LGTSMutableDictionaryNode *LGTSMDN_remove(LGTSMutableDictionaryNode *node, id key);

LGTSMutableDictionaryNode *LGTSMDN_insert(LGTSMutableDictionaryNode *original, id key, id value);

LGTSMutableDictionaryNode *LGTSMDN_Left(LGTSMutableDictionaryNode *node);
LGTSMutableDictionaryNode *LGTSMDN_Right(LGTSMutableDictionaryNode *node);

void LGTSMDN_retain(LGTSMutableDictionaryNode *node);
void LGTSMDN_release(LGTSMutableDictionaryNode *node);

id LGTSMDN_Key(LGTSMutableDictionaryNode *node);
id LGTSMDN_Data(LGTSMutableDictionaryNode *node);

LGTSMutableDictionaryNode *LGTSMDN_nodeForKey(LGTSMutableDictionaryNode *node, id key);

uint32_t LGTSMDN_validate(LGTSMutableDictionaryNode *node);

void LGTSMDN_printGraph(LGTSMutableDictionaryNode *node);
