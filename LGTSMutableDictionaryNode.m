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
#pragma mark Node management functions

id LGTSMDN_Key(LGTSMutableDictionaryNode *node) { 
	return node->key;
}

id LGTSMDN_Data(LGTSMutableDictionaryNode *node) {
	return node->data;
}

NSUInteger LGTSMDN_Count(LGTSMutableDictionaryNode *node) {
	return node->count;
}

static
void LGTSMDN_setCount(LGTSMutableDictionaryNode *node, NSUInteger count_) {
	node->count = count_;
}

static
int32_t LGTSMDN_RefCount(LGTSMutableDictionaryNode *node) {
	return node->refCount;
}

static
void LGTSMDN_writeProtect(LGTSMutableDictionaryNode *node) {
	if (node->writeable == 1) {
		//		assert(refCount == 1);
		node->writeable = 0;
		if (LGTSMDN_Left(node)) {
			LGTSMDN_writeProtect(LGTSMDN_Left(node));
		}
		
		if (LGTSMDN_Right(node)) {
			LGTSMDN_writeProtect(LGTSMDN_Right(node));
		}
	}
}

static
uint8_t LGTSMDN_Writeable(LGTSMutableDictionaryNode *node) { 
	return node->writeable;
}

LGTSMutableDictionaryNode *LGTSMDN_Left(LGTSMutableDictionaryNode *node) {
	if (node) {
		return node->left;
	} else {
		return NULL;
	}
}

LGTSMutableDictionaryNode *LGTSMDN_Right(LGTSMutableDictionaryNode *node) {
	if (node) {
		return node->right;
	} else {
		return NULL;
	}
}

static
NSUInteger LGTSMDN_Color(LGTSMutableDictionaryNode *node) {
	return node->color;
}

static
void LGTSMDN_setColor(LGTSMutableDictionaryNode *node, NSUInteger color_) {
	node->color = color_;
}

static
bool LGTSMDN_isRed(LGTSMutableDictionaryNode *node) {
	if(node && node->color) {
		return true;
	} else {
		return false;
	}
}

static
void LGTSMDN_setLeft(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *left_) {
	assert(LGTSMDN_Writeable(node));
	
	if (node->left) {
		LGTSMDN_setCount(node, LGTSMDN_Count(node)-LGTSMDN_Count(node->left));
		LGTSMDN_release(node->left);
	}
	
	node->left = left_; 
	
	if (node->left) {
		LGTSMDN_retain(node->left);
		LGTSMDN_setCount(node, LGTSMDN_Count(node)+LGTSMDN_Count(node->left));
	}
}

static
void LGTSMDN_setRight(LGTSMutableDictionaryNode *node, LGTSMutableDictionaryNode *right_)  {
	assert(LGTSMDN_Writeable(node));
	
	if (node->right) {
		LGTSMDN_setCount(node, LGTSMDN_Count(node)-LGTSMDN_Count(node->right));
		LGTSMDN_release(node->right);
	}
	
	node->right = right_; 
	
	if (node->right) {
		LGTSMDN_retain(node->right);
		LGTSMDN_setCount(node, LGTSMDN_Count(node)+LGTSMDN_Count(node->right));
	}
}

static
void LGTSMDN_refreshCount(LGTSMutableDictionaryNode *node)  {
	node->count = 1;
	if (LGTSMDN_Right(node)) {
		node->count += LGTSMDN_Count(LGTSMDN_Right(node));
	}
	
	if (LGTSMDN_Left(node)) {
		node->count += LGTSMDN_Count(LGTSMDN_Left(node));
	}
}

#pragma mark -
#pragma mark Data and Key functions

static
void LGTSMDN_setData(LGTSMutableDictionaryNode *node, id data_) {
	assert(node->writeable == 1);
	[node->data release];
	node->data = [data_ retain];
}

static
void LGTSMDN_setKey(LGTSMutableDictionaryNode *node, id key_) {
	assert(node->writeable == 1);
	[node->key release];
	node->key = [key_ retain];
}

#pragma mark -
#pragma mark Allocation and deallocation routines

static
LGTSMutableDictionaryNode *LGTSMDN_create(id K, id D, 
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
	LGTSMDN_setKey(retval, K);
	LGTSMDN_setData(retval, D);
	LGTSMDN_setLeft(retval, L);
	LGTSMDN_setRight(retval, R);
	
	return retval;
}

static
void LGTSMDN_destroy(LGTSMutableDictionaryNode *node) {
	[node->key release];
	[node->data release];
	
	if (LGTSMDN_Left(node)) LGTSMDN_release(LGTSMDN_Left(node)); 
	if (LGTSMDN_Right(node)) LGTSMDN_release(LGTSMDN_Right(node));
	
	free(node);
	
	//	OSAtomicDecrement32Barrier(&gObjectAllocs);
}

static
LGTSMutableDictionaryNode *LGTSMDN_writeableNode(LGTSMutableDictionaryNode  *node) {
	if (LGTSMDN_Writeable(node)) {
		return node;
	} else {
		return LGTSMDN_create(LGTSMDN_Key(node), LGTSMDN_Data(node), LGTSMDN_Left(node), LGTSMDN_Right(node), LGTSMDN_Color(node));
	}
}

static
LGTSMutableDictionaryNode *LGTSMDN_writeableLeftChildNode(LGTSMutableDictionaryNode  *node) {
	//	assert(getWriteable(node));
	LGTSMutableDictionaryNode *retval = LGTSMDN_writeableNode(LGTSMDN_Left(node));
	LGTSMDN_setLeft(node, retval);
	
	return retval;
}

static
LGTSMutableDictionaryNode *LGTSMDN_writeableRightChildNode(LGTSMutableDictionaryNode  *node) {
	//	assert(getWriteable(node));
	LGTSMutableDictionaryNode *retval = LGTSMDN_writeableNode(LGTSMDN_Right(node));
	LGTSMDN_setRight(node, retval);
	
	return retval;
}

#pragma mark -
#pragma mark Atomic ref counting methods

void LGTSMDN_retain(LGTSMutableDictionaryNode *node) {
	if (!LGTSMDN_Writeable(node)) {
		(void)OSAtomicIncrement32Barrier(&node->refCount);
	}
}

void LGTSMDN_release(LGTSMutableDictionaryNode *node) {
	if (!LGTSMDN_Writeable(node)) {
		if (OSAtomicDecrement32Barrier(&node->refCount) == 0) {
			LGTSMDN_destroy(node);
		}
	}
}


#pragma mark -
#pragma mark Various node shuffles, see Sedgewicks LLRB 2-3 tree Java imp for details

static
LGTSMutableDictionaryNode *LGTSMDN_rotateLeft(LGTSMutableDictionaryNode  *node) {
	LGTSMutableDictionaryNode *left = LGTSMDN_writeableNode(node);
	LGTSMutableDictionaryNode *right = LGTSMDN_writeableRightChildNode(node);
	
	LGTSMDN_setColor(right, LGTSMDN_Color(left));
	LGTSMDN_setColor(left, kLGTSMutableDictionaryNodeColorRed);
	
	LGTSMDN_setRight(left, LGTSMDN_Left(right));
	LGTSMDN_setLeft(right, left);
		
	return right;
}

static
LGTSMutableDictionaryNode *LGTSMDN_rotateRight(LGTSMutableDictionaryNode  *node) {
	LGTSMutableDictionaryNode *right = LGTSMDN_writeableNode(node);
	LGTSMutableDictionaryNode *left = LGTSMDN_writeableLeftChildNode(node);
	
	LGTSMDN_setColor(left, LGTSMDN_Color(right));
	LGTSMDN_setColor(right, kLGTSMutableDictionaryNodeColorRed);

	LGTSMDN_setLeft(right, LGTSMDN_Right(left));
	LGTSMDN_setRight(left, right);

	return left;
}

static
LGTSMutableDictionaryNode *LGTSMDN_flipColors(LGTSMutableDictionaryNode *node) {
	//	NSLog(@"Color flip");
	
	LGTSMutableDictionaryNode *retval = LGTSMDN_writeableNode(node);
	LGTSMutableDictionaryNode *left = LGTSMDN_writeableLeftChildNode(retval);
	LGTSMutableDictionaryNode *right = LGTSMDN_writeableRightChildNode(retval);
	
	LGTSMDN_setColor(retval, !LGTSMDN_Color(retval));
	LGTSMDN_setColor(left, !LGTSMDN_Color(left));
	LGTSMDN_setColor(right, !LGTSMDN_Color(right));
	
	return retval;
}

static
LGTSMutableDictionaryNode *LGTSMDN_moveRedLeft(LGTSMutableDictionaryNode  *node) {                      
	LGTSMutableDictionaryNode *retval = LGTSMDN_flipColors(node);
	
	if (LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Right(retval)))) {
		LGTSMutableDictionaryNode *temp = LGTSMDN_rotateRight(LGTSMDN_Right(retval));
		LGTSMDN_setRight(retval, temp);
		retval = LGTSMDN_rotateLeft(retval);
		retval = LGTSMDN_flipColors(retval);
	}
	
	return retval; 
} 

static
LGTSMutableDictionaryNode *LGTSMDN_moveRedRight(LGTSMutableDictionaryNode  *node) {                      
	LGTSMutableDictionaryNode *retval = LGTSMDN_flipColors(node);
	
	if (LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Left(retval)))) {
		retval = LGTSMDN_rotateRight(retval);
		retval = LGTSMDN_flipColors(retval);
	} 
	return retval; 
}

static
LGTSMutableDictionaryNode *LGTSMDN_fixUp(LGTSMutableDictionaryNode *node) {
	LGTSMutableDictionaryNode *retval = LGTSMDN_writeableNode(node);
	
	if (LGTSMDN_isRed(LGTSMDN_Right(retval))) {
		retval = LGTSMDN_rotateLeft(retval);
	}
	
	if (LGTSMDN_isRed(LGTSMDN_Left(retval))
		&& LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Left(retval)))) {
		retval = LGTSMDN_rotateRight(retval);
	}
	
	if (LGTSMDN_isRed(LGTSMDN_Left(retval)) 
		&& LGTSMDN_isRed(LGTSMDN_Right(retval))) {
		retval = LGTSMDN_flipColors(retval);
	}
	
	LGTSMDN_refreshCount(retval);
	
	return retval;
}

static
LGTSMutableDictionaryNode *LGTSMDN_insertInternal(LGTSMutableDictionaryNode *node, id key, id value) {
	LGTSMutableDictionaryNode *retval, *temp;
	
	if (node == NULL) {
		retval = LGTSMDN_create(key, value, NULL, NULL, kLGTSMutableDictionaryNodeColorRed);
		
		return retval;
	}
	
	retval = LGTSMDN_writeableNode(node);
	
	NSComparisonResult cmp = [key compare:LGTSMDN_Key(node)];
	
	if (cmp == NSOrderedSame) {
		LGTSMDN_setKey(retval, key);
		LGTSMDN_setData(retval, value);
		return retval;
	} else if (cmp == NSOrderedAscending) {
		temp = LGTSMDN_insertInternal(LGTSMDN_Left(node), key, value);
		LGTSMDN_setLeft(retval, temp);
	} else if (cmp == NSOrderedDescending) {
		temp = LGTSMDN_insertInternal(LGTSMDN_Right(node), key, value);
		LGTSMDN_setRight(retval, temp);
	}
	
	return LGTSMDN_fixUp(retval);
}

static
LGTSMutableDictionaryNode * LGTSMDN_minNode(LGTSMutableDictionaryNode *node) {
	if (LGTSMDN_Left(node)) {
		return LGTSMDN_minNode(LGTSMDN_Left(node));
	} else {
		return node;
	}
}

static
LGTSMutableDictionaryNode * LGTSMDN_removeMinNode(LGTSMutableDictionaryNode *node) {
	if (!LGTSMDN_Left(node)) {
		return NULL;
	}
	
	LGTSMutableDictionaryNode *retval = LGTSMDN_writeableNode(node);
	
	if (!LGTSMDN_isRed(LGTSMDN_Left(retval))
		&& !LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Left(retval)))) {
		retval = LGTSMDN_moveRedLeft(retval);
	}
	
	LGTSMDN_setLeft(retval, LGTSMDN_removeMinNode(LGTSMDN_Left(retval)));
	
	return LGTSMDN_fixUp(retval);
}

static
LGTSMutableDictionaryNode *LGTSMDN_removeInternal(LGTSMutableDictionaryNode *node, id key) {
	LGTSMutableDictionaryNode* retval = node;
	
	NSComparisonResult cmp = [key compare:LGTSMDN_Key(retval)];
	
	if(cmp != NSOrderedSame && LGTSMDN_Count(node) == 1) {
		return node;
	}
	
	if (cmp == NSOrderedAscending) {
		if (!LGTSMDN_isRed(LGTSMDN_Left(retval))
			&& !LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Left(retval)))) {
			retval = LGTSMDN_moveRedLeft(retval);
		}
		if (LGTSMDN_Left(retval)) {
			retval = LGTSMDN_writeableNode(retval);
			LGTSMDN_setLeft(retval, LGTSMDN_removeInternal(LGTSMDN_Left(retval), key));
		} else {
			retval = NULL;
		}
	} else {
		if (LGTSMDN_isRed(LGTSMDN_Left(retval))) {
			retval = LGTSMDN_writeableNode(retval);
			retval = LGTSMDN_rotateRight(retval);
		}
			
		NSComparisonResult cmp = [key compare:LGTSMDN_Key(retval)];

		if (cmp == NSOrderedSame && !LGTSMDN_Right(retval)) {
			return NULL;
		}
		
		if (!LGTSMDN_isRed(LGTSMDN_Right(retval))
			&& !LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Right(retval)))) {
			retval = LGTSMDN_moveRedRight(retval);
		}
		
		cmp = [key compare:LGTSMDN_Key(retval)];

		if (cmp == NSOrderedSame) {
			retval = LGTSMDN_writeableNode(retval);
			LGTSMutableDictionaryNode *temp = LGTSMDN_minNode(LGTSMDN_Right(retval));
			
			LGTSMDN_setKey(retval, LGTSMDN_Key(temp));
			LGTSMDN_setData(retval, LGTSMDN_Data(temp));
			LGTSMDN_setRight(retval, LGTSMDN_removeMinNode(LGTSMDN_Right(retval)));
			
		} else {
			if (LGTSMDN_Right(retval)) {
				retval = LGTSMDN_writeableNode(retval);
				LGTSMDN_setRight(retval, LGTSMDN_removeInternal(LGTSMDN_Right(retval), key));
			}
		}
	}
	
	if (retval) {
		retval = LGTSMDN_fixUp(retval);
	}
	
	return retval;
}

#pragma mark -
#pragma mark Insert, Remove, and Search interface for objc

LGTSMutableDictionaryNode *LGTSMDN_insert(LGTSMutableDictionaryNode *node, id key, id value) {
	LGTSMutableDictionaryNode *retval = NULL;
	
	retval =  LGTSMDN_insertInternal(node, key, value);
	LGTSMDN_setColor(retval, kLGTSMutableDictionaryNodeColorBlack);
	LGTSMDN_writeProtect(retval);
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMDN_nodeForKey(LGTSMutableDictionaryNode *node, id key) { 
	LGTSMutableDictionaryNode *x = node; 
	while (x != NULL) {
		NSComparisonResult cmp = [key compare:LGTSMDN_Key(x)];
		if (cmp == NSOrderedSame) {
			return x;
		} else if (cmp == NSOrderedAscending) {
			x = LGTSMDN_Left(x);
		} else if (cmp == NSOrderedDescending) {
			x = LGTSMDN_Right(x);
		}
	} 
	return NULL; 
}

LGTSMutableDictionaryNode * LGTSMDN_remove(LGTSMutableDictionaryNode *node, id key) {
	LGTSMutableDictionaryNode *retval = LGTSMDN_removeInternal(node, key);
	if (retval) {
		//retval = writeableNode();
		LGTSMDN_setColor(retval, kLGTSMutableDictionaryNodeColorBlack);
		LGTSMDN_writeProtect(retval);
	}
	
	return retval;
}

#pragma mark -
#pragma mark Validation and debugging

uint32_t LGTSMDN_validate(LGTSMutableDictionaryNode *node) {
	if (LGTSMDN_Right(node) && !LGTSMDN_Left(node)) {
		NSLog(@"Right lean error");
	}
	
	if (LGTSMDN_Right(node) && LGTSMDN_Left(node)
		&& LGTSMDN_Color(LGTSMDN_Right(node)) != LGTSMDN_Color(LGTSMDN_Right(node))) {
		NSLog(@"Sibling color error");
	}
	
	if (LGTSMDN_isRed(LGTSMDN_Left(node))
		&&	LGTSMDN_isRed(LGTSMDN_Left(LGTSMDN_Left(node)))) {
		NSLog(@"Double red error");
	}
	
	uint32_t left_height = 0;
	uint32_t right_height = 0;
	uint32_t height = 0;
	
	if (LGTSMDN_Left(node)) {
		left_height = LGTSMDN_validate(LGTSMDN_Left(node));
	}
	
	if (LGTSMDN_Right(node)) {
		right_height = LGTSMDN_validate(LGTSMDN_Right(node));
	}
	
	if (left_height != right_height) {
		NSLog(@"Uneven leg asert");
	}
	
	if (LGTSMDN_isRed(node)) {
		height = left_height + 0;
	} else {
		height = left_height + 1;
	}
	
	
	return height;
}

static
NSString *LGTSMDN_graphColors(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (LGTSMDN_isRed(node)) {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=red, style=filled];\n", LGTSMDN_Key(node), LGTSMDN_RefCount(node)];
	} else {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=lightblue2, style=filled];\n", LGTSMDN_Key(node), LGTSMDN_RefCount(node)];
	}
	
	[str appendFormat:@"\t\"%lx\";\n", node];
	
	if (LGTSMDN_Left(node)) {
		[str appendString:LGTSMDN_graphColors(LGTSMDN_Left(node))];
	}
	
	if (LGTSMDN_Right(node)) {
		[str appendString:LGTSMDN_graphColors(LGTSMDN_Right(node))];
	}
	
	return [str autorelease];
}

static
NSString *LGTSMDN_graphConnections(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (LGTSMDN_Left(node)) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\"[ label = \"L\" ];\n", node, LGTSMDN_Left(node)];
	}
	
	if (LGTSMDN_Right(node)) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\" [ label = \"R\" ];\n", node, LGTSMDN_Right(node)];
	}
	
	if (LGTSMDN_Left(node)) {
		[str appendString:LGTSMDN_graphConnections(LGTSMDN_Left(node))];
	}
	
	if (LGTSMDN_Right(node)) {
		[str appendString:LGTSMDN_graphConnections(LGTSMDN_Right(node))];
	}
	
	return [str autorelease];
}

void LGTSMDN_printGraph(LGTSMutableDictionaryNode *node) {
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"digraph LLRBtree {\n"];
	[str appendString:@"\tsize=\"6,6\";\n"];
	[str appendString:LGTSMDN_graphColors(node)];
	[str appendString:LGTSMDN_graphConnections(node)];
	[str appendString:@"}\n"];
	
	NSLog(@"Graph:\n%@", str);
	[str release];
}
