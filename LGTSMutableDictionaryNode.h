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

class LGTSMutableDictionaryNode {
	__strong id key;
	__strong id data;
	NSUInteger count;
	LGTSMutableDictionaryNode *left;
	LGTSMutableDictionaryNode *right;
	volatile int32_t refCount;

	uint8_t color:1;
	uint8_t writeable:1;

public:

	void refreshCount(void);
	
	NSUInteger getCount() { return count; };
	void setCount(NSUInteger count_) { count = count_; }
	volatile int32_t getRefCount() { return refCount; };
	
	NSUInteger getColor() { return color; };
	void setColor(NSUInteger color_) { color = color_; }
	
	void setKey(id key_);
	void setData(id data_);
	
	uint8_t getWriteable() { return writeable; };
	void writeProtect();
	
	LGTSMutableDictionaryNode *getLeft() { return left; };
	void setLeft(LGTSMutableDictionaryNode *left_);
	LGTSMutableDictionaryNode *getRight() { return right; };
	void setRight(LGTSMutableDictionaryNode *right_);
	
	LGTSMutableDictionaryNode *writeableNode(void);
	LGTSMutableDictionaryNode *writeableLeftChildNode(void);
	LGTSMutableDictionaryNode *writeableRightChildNode(void);
	
	LGTSMutableDictionaryNode *moveRedLeft(void);
	LGTSMutableDictionaryNode *moveRedRight(void);   
	LGTSMutableDictionaryNode *rotateLeft(void);
	LGTSMutableDictionaryNode *rotateRight(void);
	LGTSMutableDictionaryNode *flipColors(void);
	
	LGTSMutableDictionaryNode *fixUp(void);

	uint32_t validate(LGTSMutableDictionaryNode *node);
	
	NSString *graphColors(void);
	NSString *graphConnections(void);
	
	LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::remove(LGTSMutableDictionaryNode *node, id key);
	LGTSMutableDictionaryNode *insert(LGTSMutableDictionaryNode *originalp, id key, id value);

	LGTSMutableDictionaryNode *minNode(void);
	LGTSMutableDictionaryNode *removeMinNode(void);
	
	LGTSMutableDictionaryNode(id K, id D,
							  LGTSMutableDictionaryNode *L, LGTSMutableDictionaryNode *R, 
							  uint8_t C);
	~LGTSMutableDictionaryNode();

	void retain();
	void release();




	id getKey() { return key; };
	id getData() { return data; };
	
	LGTSMutableDictionaryNode *nodeForKey(id key);
	LGTSMutableDictionaryNode *insert(id key, id value);
	LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::remove(id key);
	
	uint32_t validate(void);
	void printGraph(void);
};
