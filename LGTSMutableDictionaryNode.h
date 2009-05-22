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
	NSUInteger getCount(LGTSMutableDictionaryNode *node);
	
	void setKey(LGTSMutableDictionaryNode *node, id key_);
	void setData(LGTSMutableDictionaryNode *node, id data_);
	
	LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::remove(LGTSMutableDictionaryNode *node, id key);

	LGTSMutableDictionaryNode *insert(LGTSMutableDictionaryNode *original, id key, id value);
	
	LGTSMutableDictionaryNode(id K, id D,
							  LGTSMutableDictionaryNode *L, LGTSMutableDictionaryNode *R, 
							  uint8_t C);
	~LGTSMutableDictionaryNode();
	
	LGTSMutableDictionaryNode *getLeft(LGTSMutableDictionaryNode *node);
	LGTSMutableDictionaryNode *getRight(LGTSMutableDictionaryNode *node);

	void retain(LGTSMutableDictionaryNode *node);
	void release(LGTSMutableDictionaryNode *node);

	id getKey(LGTSMutableDictionaryNode *node);
	id getData(LGTSMutableDictionaryNode *node);
	
	LGTSMutableDictionaryNode *nodeForKey(LGTSMutableDictionaryNode *node, id key);
	
	uint32_t validate(LGTSMutableDictionaryNode *node);

	void printGraph(LGTSMutableDictionaryNode *node);

private:
	void setLeft(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *left_);
	void LGTSMutableDictionaryNode::setRight(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *right_);
	
	LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::removeInternal(LGTSMutableDictionaryNode *node, id key);
	
	NSUInteger getColor(LGTSMutableDictionaryNode *node);
	void setColor(LGTSMutableDictionaryNode *node, NSUInteger color_);
	bool isRed(LGTSMutableDictionaryNode *node);
	
	void setCount(LGTSMutableDictionaryNode *node, NSUInteger count_);
	volatile int32_t getRefCount(LGTSMutableDictionaryNode *node);
	
	uint8_t getWriteable(LGTSMutableDictionaryNode *node);
	
	void refreshCount(LGTSMutableDictionaryNode *node);
	void writeProtect(LGTSMutableDictionaryNode *node);
	
	NSString *graphColors(LGTSMutableDictionaryNode *node);
	NSString *graphConnections(LGTSMutableDictionaryNode *node);
	
	LGTSMutableDictionaryNode *insertInternal(LGTSMutableDictionaryNode *original, id key, id value);

	LGTSMutableDictionaryNode *fixUp(LGTSMutableDictionaryNode *node);

	LGTSMutableDictionaryNode *minNode(LGTSMutableDictionaryNode *node);
	LGTSMutableDictionaryNode *removeMinNode(LGTSMutableDictionaryNode *node);
	
	LGTSMutableDictionaryNode *writeableNode(LGTSMutableDictionaryNode  *node);
	LGTSMutableDictionaryNode *writeableLeftChildNode(LGTSMutableDictionaryNode  *node);
	LGTSMutableDictionaryNode *writeableRightChildNode(LGTSMutableDictionaryNode  *node);
	
	LGTSMutableDictionaryNode *moveRedLeft(LGTSMutableDictionaryNode  *node);
	LGTSMutableDictionaryNode *moveRedRight(LGTSMutableDictionaryNode  *node);   
	LGTSMutableDictionaryNode *rotateLeft(LGTSMutableDictionaryNode  *node);
	LGTSMutableDictionaryNode *rotateRight(LGTSMutableDictionaryNode  *node);
	LGTSMutableDictionaryNode *flipColors(LGTSMutableDictionaryNode  *node);
};
