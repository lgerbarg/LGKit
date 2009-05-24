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
 *  LGTSMutableDictionaryNode.cpp
 *  LGTSMutableDictionary
 *
 *  Created by Louis Gerbarg on 5/16/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */


#include <libkern/OSAtomic.h>

#include "LGTSMutableDictionaryNode.h"

int32_t gObjectAllocs = 0;

const uint8_t kLGTSMutableDictionaryNodeColorBlack = 0;
const uint8_t kLGTSMutableDictionaryNodeColorRed = 1;

#pragma mark -
#pragma mark Constructor and Destructor

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::create(id K, id D, 
										 LGTSMutableDictionaryNode *L, LGTSMutableDictionaryNode *R,
										 uint8_t C) {
	LGTSMutableDictionaryNode *retval = (LGTSMutableDictionaryNode *)malloc(sizeof(LGTSMutableDictionaryNode));
	retval->data = nil;
	retval->key = nil;
	retval->left = NULL;
	retval->right = NULL;
	retval->color = C;
	retval->count = 1;
	retval->refCount = 1;
	retval->writeable = 1;
	setKey(retval, K);
	setData(retval, D);
	setLeft(retval, L);
	setRight(retval, R);
	
	return retval;
}

void LGTSMutableDictionaryNode::destroy(LGTSMutableDictionaryNode *node) {
	[node->key release];
	[node->data release];
	
	if (getLeft(node)) release(getLeft(node)); 
	if (getRight(node)) release(getRight(node));
	
	free(node);
	
	//	OSAtomicDecrement32Barrier(&gObjectAllocs);
}

#pragma mark -
#pragma mark Atomic ref counting methods

void LGTSMutableDictionaryNode::retain(LGTSMutableDictionaryNode *node) {
	if (!getWriteable(node)) {
		(void)OSAtomicIncrement32Barrier(&node->refCount);
	}
}

void LGTSMutableDictionaryNode::release(LGTSMutableDictionaryNode *node) {
	if (!getWriteable(node)) {
		if (OSAtomicDecrement32Barrier(&node->refCount) == 0) {
			destroy(node);
		}
	}
}

#pragma mark -
#pragma mark Node management functions

id LGTSMutableDictionaryNode::getKey(LGTSMutableDictionaryNode *node) { 
	return node->key;
}

id LGTSMutableDictionaryNode::getData(LGTSMutableDictionaryNode *node) {
	return node->data;
}

NSUInteger LGTSMutableDictionaryNode::getCount(LGTSMutableDictionaryNode *node) {
	return node->count;
}

void LGTSMutableDictionaryNode::setCount(LGTSMutableDictionaryNode *node, NSUInteger count_) {
	node->count = count_;
}

volatile int32_t LGTSMutableDictionaryNode::getRefCount(LGTSMutableDictionaryNode *node) {
	return node->refCount;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableNode(LGTSMutableDictionaryNode  *node) {
	if (getWriteable(node)) {
		return node;
	} else {
		return create(getKey(node), getData(node), getLeft(node), getRight(node), getColor(node));
	}
}

void LGTSMutableDictionaryNode::writeProtect(LGTSMutableDictionaryNode *node) {
	if (node->writeable == 1) {
		//		assert(refCount == 1);
		node->writeable = 0;
		if (getLeft(node)) {
			writeProtect(getLeft(node));
		}
		
		if (getRight(node)) {
			writeProtect(getRight(node));
		}
	}
}

uint8_t LGTSMutableDictionaryNode::getWriteable(LGTSMutableDictionaryNode *node) { 
	return node->writeable;
}


LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableLeftChildNode(LGTSMutableDictionaryNode  *node) {
//	assert(getWriteable(node));
	LGTSMutableDictionaryNode *retval = writeableNode(getLeft(node));
	setLeft(node, retval);
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableRightChildNode(LGTSMutableDictionaryNode  *node) {
//	assert(getWriteable(node));
	LGTSMutableDictionaryNode *retval = writeableNode(getRight(node));
	setRight(node, retval);
	
	return retval;
}




void LGTSMutableDictionaryNode::setLeft(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *left_) {
	assert(getWriteable(node));
	
	if (node->left) {
		setCount(node, getCount(node)-getCount(node->left));
		release(node->left);
	}
	
	node->left = left_; 
	
	if (node->left) {
		retain(node->left);
		setCount(node, getCount(node)+getCount(node->left));
	}
}

void LGTSMutableDictionaryNode::setRight(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *right_)  {
	assert(getWriteable(node));
	
	if (node->right) {
		setCount(node, getCount(node)-getCount(node->right));
		release(node->right);
	}
	
	node->right = right_; 
	
	if (node->right) {
		retain(node->right);
		setCount(node, getCount(node)+getCount(node->right));
	}
}

void LGTSMutableDictionaryNode::refreshCount(LGTSMutableDictionaryNode *node)  {
	node->count = 1;
	if (getRight(node)) {
		node->count += getCount(getRight(node));
	}
	
	if (getLeft(node)) {
		node->count += getCount(getLeft(node));
	}
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::getLeft(LGTSMutableDictionaryNode *node) {
	if (node) {
		return node->left;
	} else {
		return NULL;
	}
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::getRight(LGTSMutableDictionaryNode *node) {
	if (node) {
		return node->right;
	} else {
		return NULL;
	}
}

NSUInteger LGTSMutableDictionaryNode::getColor(LGTSMutableDictionaryNode *node) {
	return node->color;
}

void LGTSMutableDictionaryNode::setColor(LGTSMutableDictionaryNode *node, NSUInteger color_) {
	node->color = color_;
}

bool LGTSMutableDictionaryNode::isRed(LGTSMutableDictionaryNode *node) {
	if(node && node->color) {
		return true;
	} else {
		return false;
	}
}

#pragma mark -
#pragma mark Data and Key functions

void LGTSMutableDictionaryNode::setData(LGTSMutableDictionaryNode *node, id data_) {
	assert(node->writeable == 1);
	[node->data release];
	node->data = [data_ retain];
}

void LGTSMutableDictionaryNode::setKey(LGTSMutableDictionaryNode *node, id key_) {
	assert(node->writeable == 1);
	[node->key release];
	node->key = [key_ retain];
}

#pragma mark -
#pragma mark Various node shuffles, see Sedgewicks LLRB 2-3 tree Java imp for details

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::rotateLeft(LGTSMutableDictionaryNode  *node) {
	LGTSMutableDictionaryNode *left = writeableNode(node);
	LGTSMutableDictionaryNode *right = writeableRightChildNode(node);
	
	setColor(right, getColor(left));
	setColor(left, kLGTSMutableDictionaryNodeColorRed);
	
	setRight(left, getLeft(right));
	setLeft(right, left);
		
	return right;
}


LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::rotateRight(LGTSMutableDictionaryNode  *node) {
	LGTSMutableDictionaryNode *right = writeableNode(node);
	LGTSMutableDictionaryNode *left = writeableLeftChildNode(node);
	
	setColor(left, getColor(right));
	setColor(right, kLGTSMutableDictionaryNodeColorRed);

	setLeft(right, getRight(left));
	setRight(left, right);

	return left;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::moveRedLeft(LGTSMutableDictionaryNode  *node) {                      
	LGTSMutableDictionaryNode *retval = flipColors(node);
	
	if (isRed(getLeft(getRight(retval)))) {
		LGTSMutableDictionaryNode *temp = rotateRight(getRight(retval));
		setRight(retval, temp);
		retval = rotateLeft(retval);
		retval = flipColors(retval);
	}
	
	return retval; 
} 

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::moveRedRight(LGTSMutableDictionaryNode  *node) {                      
	LGTSMutableDictionaryNode *retval = flipColors(node);
	
	if (isRed(getLeft(getLeft(retval)))) {
		retval = rotateRight(retval);
		retval = flipColors(retval);
	} 
	return retval; 
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::fixUp(LGTSMutableDictionaryNode *node) {
	LGTSMutableDictionaryNode *retval = writeableNode(node);
	
	if (isRed(getRight(retval))) {
		retval = rotateLeft(retval);
	}
	
	if (isRed(getLeft(retval))
		&& isRed(getLeft(getLeft(retval)))) {
		retval = rotateRight(retval);
	}
	
	if (isRed(getLeft(retval)) 
		&& isRed(getRight(retval))) {
		retval = flipColors(retval);
	}
	
	refreshCount(retval);
	
	return retval;
}


LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::flipColors(LGTSMutableDictionaryNode *node) {
//	NSLog(@"Color flip");

	LGTSMutableDictionaryNode *retval = writeableNode(node);
	LGTSMutableDictionaryNode *left = writeableLeftChildNode(retval);
	LGTSMutableDictionaryNode *right = writeableRightChildNode(retval);
	
	setColor(retval, !getColor(retval));
	setColor(left, !getColor(left));
	setColor(right, !getColor(right));
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::insertInternal(LGTSMutableDictionaryNode *original, id key, id value) {
	LGTSMutableDictionaryNode *retval, *temp;
	
	if (original == NULL) {
		retval = create(key, value, NULL, NULL, kLGTSMutableDictionaryNodeColorRed);
		
		return retval;
	}
	
	retval=writeableNode(original);
	
	NSComparisonResult cmp = [key compare:getKey(original)];
	
	if (cmp == NSOrderedSame) {
		retval->setKey(retval, key);
		retval->setData(retval, value);
		return retval;
	} else if (cmp == NSOrderedAscending) {
		temp = insertInternal(getLeft(original), key, value);
		setLeft(retval, temp);
	} else if (cmp == NSOrderedDescending) {
		temp = insertInternal(getRight(original), key, value);
		setRight(retval, temp);
	}
	
	return fixUp(retval);
}

LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::minNode(LGTSMutableDictionaryNode *node) {
	if (getLeft(node)) {
		return minNode(getLeft(node));
	} else {
		return node;
	}
}


LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::removeMinNode(LGTSMutableDictionaryNode *node) {

	if (!getLeft(node)) {
		return NULL;
	}
	
	LGTSMutableDictionaryNode *retval = writeableNode(node);
	
	if (!isRed(getLeft(retval))
		&& !isRed(getLeft(getLeft(retval)))) {
		retval = moveRedLeft(retval);
	}
	
	setLeft(retval, removeMinNode(getLeft(retval)));
	
	return fixUp(retval);
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::removeInternal(LGTSMutableDictionaryNode *node, id key) {
	LGTSMutableDictionaryNode* retval = node;
	
	NSComparisonResult cmp = [key compare:getKey(retval)];
	
	if(cmp != NSOrderedSame && getCount(node) == 1) {
		return node;
	}
	
	if (cmp == NSOrderedAscending) {
		if (!isRed(getLeft(retval))
			&& !isRed(getLeft(getLeft(retval)))) {
			retval = moveRedLeft(retval);
		}
		if (getLeft(retval)) {
			retval = writeableNode(retval);
			setLeft(retval, removeInternal(getLeft(retval), key));
		} else {
			retval = NULL;
		}
	} else {
		if (isRed(getLeft(retval))) {
			retval = writeableNode(retval);
			retval = rotateRight(retval);
		}
			
		NSComparisonResult cmp = [key compare:getKey(retval)];

		if (cmp == NSOrderedSame && !getRight(retval)) {
			return NULL;
		}
		
		if (!isRed(getRight(retval))
			&& !isRed(getLeft(getRight(retval)))) {
			retval = moveRedRight(retval);
		}
		
		cmp = [key compare:getKey(retval)];

		if (cmp == NSOrderedSame) {
			retval = writeableNode(retval);
			LGTSMutableDictionaryNode *temp = minNode(getRight(retval));
			
			setKey(retval, getKey(temp));
			setData(retval,getData(temp));
			setRight(retval, removeMinNode(getRight(retval)));
			
		} else {
			if (getRight(retval)) {
				retval = writeableNode(retval);
				setRight(retval, removeInternal(getRight(retval), key));
			}
		}
	}
	
	if (retval) {
		retval = fixUp(retval);
	}
	
	return retval;
}

#pragma mark -
#pragma mark Insert, Remove, and Search interface for objc

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::insert(LGTSMutableDictionaryNode *node, id key, id value) {
	LGTSMutableDictionaryNode *retval = NULL;
	
	retval =  insertInternal(node, key, value);
	setColor(retval, kLGTSMutableDictionaryNodeColorBlack);
	writeProtect(retval);
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::nodeForKey(LGTSMutableDictionaryNode *node, id key) { 
	LGTSMutableDictionaryNode *x = node; 
	while (x != NULL) {
		NSComparisonResult cmp = [key compare:getKey(x)];
		if (cmp == NSOrderedSame) {
			return x;
		} else if (cmp == NSOrderedAscending) {
			x = getLeft(x);
		} else if (cmp == NSOrderedDescending) {
			x = getRight(x);
		}
	} 
	return NULL; 
}

LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::remove(LGTSMutableDictionaryNode *node, id key) {
	LGTSMutableDictionaryNode *retval = removeInternal(node, key);
	if (retval) {
		//retval = writeableNode();
		setColor(retval, kLGTSMutableDictionaryNodeColorBlack);
		writeProtect(retval);
	}
	
	return retval;
}

#pragma mark -
#pragma mark Validation and debugging

uint32_t LGTSMutableDictionaryNode::validate(LGTSMutableDictionaryNode *node) {
	if (getRight(node) && !getLeft(node)) {
		NSLog(@"Right lean error");
	}
	
	if (getRight(node) && getLeft(node)
		&& getColor(getRight(node)) != getColor(getRight(node))) {
		NSLog(@"Sibling color error");
	}
	
	if (isRed(getLeft(node))
		&&	isRed(getLeft(getLeft(node)))) {
		NSLog(@"Double red error");
	}
	
	uint32_t left_height = 0;
	uint32_t right_height = 0;
	uint32_t height = 0;
	
	if (getLeft(node)) {
		left_height = validate(getLeft(node));
	}
	
	if (getRight(node)) {
		right_height = validate(getRight(node));
	}
	
	if (left_height != right_height) {
		NSLog(@"Uneven leg asert");
	}
	
	if (isRed(node)) {
		height = left_height + 0;
	} else {
		height = left_height + 1;
	}
	
	
	return height;
}


void LGTSMutableDictionaryNode::printGraph(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"digraph LLRBtree {\n"];
	[str appendString:@"\tsize=\"6,6\";\n"];
	[str appendString:graphColors(node)];
	[str appendString:graphConnections(node)];
	[str appendString:@"}\n"];
	
	NSLog(@"Graph:\n%@", str);
	[str release];
}

NSString *LGTSMutableDictionaryNode::graphColors(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (isRed(node)) {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=red, style=filled];\n", key, getRefCount(node)];
	} else {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=lightblue2, style=filled];\n", key, getRefCount(node)];
	}
	
	[str appendFormat:@"\t\"%lx\";\n", node];
	
	if (getLeft(node)) {
		[str appendString:graphColors(getLeft(node))];
	}
	
	if (getRight(node)) {
		[str appendString:graphColors(getRight(node))];
	}
	
	return [str autorelease];
}

NSString *LGTSMutableDictionaryNode::graphConnections(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (getLeft(node)) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\"[ label = \"L\" ];\n", node, getLeft(node)];
	}
	
	if (getRight(this)) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\" [ label = \"R\" ];\n", node, getRight(node)];
	}
	
	if (getLeft(node)) {
		[str appendString:graphConnections(getLeft(node))];
	}
	
	if (getRight(node)) {
		[str appendString:graphConnections(getRight(node))];
	}
	
	return [str autorelease];
}
