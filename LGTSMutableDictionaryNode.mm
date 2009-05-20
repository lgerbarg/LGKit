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

LGTSMutableDictionaryNode::LGTSMutableDictionaryNode(id K, id D,
						  LGTSMutableDictionaryNode *L, LGTSMutableDictionaryNode *R, 
													 uint8_t C) :
data(nil), key(nil), left(0), right(0), writeable(1),
color(C), refCount(1), count(1) {
	setKey(K);
	setData(D);
	setLeft(L);
	setRight(R);
//	OSAtomicIncrement32Barrier(&gObjectAllocs);
}

LGTSMutableDictionaryNode::~LGTSMutableDictionaryNode() {
	[key release];
	[data release];
	
	if (getLeft()) getLeft()->release(); 
	if (getRight()) getRight()->release();
	
	//	OSAtomicDecrement32Barrier(&gObjectAllocs);
}

#pragma mark -
#pragma mark Atomic ref counting methods

void LGTSMutableDictionaryNode::retain() {
	if (!getWriteable()) {
		(void)OSAtomicIncrement32Barrier(&refCount);
	}
}

void LGTSMutableDictionaryNode::release() {
	if (!getWriteable()) {
		if (OSAtomicDecrement32Barrier(&refCount) == 0) {
			assert(this->getRefCount() == 0);
			delete this;
		}
	}
}

#pragma mark -
#pragma mark Node management functions

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableNode(void) {
	if (getWriteable()) {
		return this;
	} else {
		return  new LGTSMutableDictionaryNode(getKey(), getData(), getLeft(), getRight(), getColor());
	}
}

void LGTSMutableDictionaryNode::writeProtect(void) {
	if (writeable == 1) {
		//		assert(refCount == 1);
		writeable = 0;
		if (getLeft()) {
			getLeft()->writeProtect();
		}
		
		if (getRight()) {
			getRight()->writeProtect();
		}
	}
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableLeftChildNode() {
//	assert(getWriteable());
	LGTSMutableDictionaryNode *retval = getLeft()->writeableNode();
	setLeft(retval);
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::writeableRightChildNode() {
//	assert(getWriteable());
	LGTSMutableDictionaryNode *retval = getRight()->writeableNode();
	setRight(retval);
	
	return retval;
}




void LGTSMutableDictionaryNode::setLeft(LGTSMutableDictionaryNode *left_) {
	assert(getWriteable());
	
	if (left) {
		setCount(getCount()-left->getCount());
		left->release();
	}
	
	left = left_; 
	
	if (left) {
		left->retain();
		setCount(getCount()+left->getCount());
	}
}

void LGTSMutableDictionaryNode::setRight(LGTSMutableDictionaryNode *right_)  {
	assert(getWriteable());
	
	if (right) {
		setCount(getCount()-right->getCount());
		right->release();
	}
	
	right = right_; 
	
	if (right) {
		right->retain();
		setCount(getCount()+right->getCount());
	}
}
	
void LGTSMutableDictionaryNode::refreshCount(void)  {
	count = 1;
	if (getRight()) {
		count += getRight()->getCount();
	}
	
	if (getLeft()) {
		count += getLeft()->getCount();
	}
}

#pragma mark -
#pragma mark Data and Key functions

void LGTSMutableDictionaryNode::setData(id data_) {
	assert(writeable == 1);
	[data release];
	data = [data_ retain];
}

void LGTSMutableDictionaryNode::setKey(id key_) {
	assert(writeable == 1);
	[key release];
	key = [key_ retain];
}

#pragma mark -
#pragma mark Various node shuffles, see Sedgewicks LLRB 2-3 tree Java imp for details

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::rotateLeft(void) {
	LGTSMutableDictionaryNode *left = writeableNode();
	LGTSMutableDictionaryNode *right = writeableRightChildNode();
	
	right->setColor(left->getColor());
	left->setColor(kLGTSMutableDictionaryNodeColorRed);
	
	left->setRight(right->getLeft());
	right->setLeft(left);
		
	return right;
}


LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::rotateRight(void) {
	LGTSMutableDictionaryNode *right = writeableNode();
	LGTSMutableDictionaryNode *left = writeableLeftChildNode();
	
	left->setColor(right->getColor());
	right->setColor(kLGTSMutableDictionaryNodeColorRed);

	right->setLeft(left->getRight());
	left->setRight(right);

	return left;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::moveRedLeft(void) {                      
	LGTSMutableDictionaryNode *retval = this->flipColors();
	
	if (retval-getRight() && retval->getRight()->getLeft()
		&& retval->getRight()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		LGTSMutableDictionaryNode *temp = retval->getRight()->rotateRight();
		retval->setRight(temp);
		retval = retval->rotateLeft();
		retval = retval->flipColors();
	}
	
	return retval; 
} 

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::moveRedRight(void) {                      
	LGTSMutableDictionaryNode *retval = this->flipColors();
	
	if (retval->getLeft() && retval->getLeft()->getLeft()
		&& retval->getLeft()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		retval = retval->rotateRight();
		retval = retval->flipColors();
	} 
	return retval; 
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::fixUp(void) {
	LGTSMutableDictionaryNode *retval = writeableNode();
	
	if (retval->getRight() && retval->getRight()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		retval = retval->rotateLeft();
	}
	
	if (retval->getLeft() && retval->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed
		&& retval->getLeft()->getLeft() && retval->getLeft()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		retval = retval->rotateRight();
	}
	
	if (retval->getLeft() && retval->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed 
		&& retval->getRight() && retval->getRight()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		retval = retval->flipColors();
	}
	
	retval->refreshCount();
	
	return retval;
}


LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::flipColors(void) {
//	NSLog(@"Color flip");

	LGTSMutableDictionaryNode *retval = writeableNode();
	LGTSMutableDictionaryNode *left = retval->writeableLeftChildNode();
	LGTSMutableDictionaryNode *right = retval->writeableRightChildNode();
	
	retval->setColor(!retval->getColor());
	left->setColor(!left->getColor());
	right->setColor(!right->getColor());
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::insert(LGTSMutableDictionaryNode *original, id key, id value) {
	LGTSMutableDictionaryNode *retval, *temp;
	
	if (original == NULL) {
		retval = new LGTSMutableDictionaryNode(key, value, NULL, NULL, kLGTSMutableDictionaryNodeColorRed);
		
		return retval;
	}
	
	retval=original->writeableNode();
	
	NSComparisonResult cmp = [key compare:original->getKey()];
	
	if (cmp == NSOrderedSame) {
		retval->setKey(key);
		retval->setData(value);
		return retval;
	} else if (cmp == NSOrderedAscending) {
		temp = insert(original->getLeft(), key, value);
		retval->setLeft(temp);
	} else if (cmp == NSOrderedDescending) {
		temp = insert(original->getRight(), key, value);
		retval->setRight(temp);
	}
	
	return retval->fixUp();
}

LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::minNode(void) {
	if (getLeft()) {
		return getLeft()->minNode();
	} else {
		return this;
	}
}


LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::removeMinNode(void) {

	if (!getLeft()) {
		return NULL;
	}
	
	LGTSMutableDictionaryNode *retval = writeableNode();
	
	if (((retval->getLeft() && retval->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
			|| !retval->getLeft())
		&& ((retval->getLeft()->getLeft() && retval->getLeft()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
			|| !retval->getLeft() || !retval->getLeft()->getLeft())) {
		retval = retval->moveRedLeft();
	}
	
	retval->setLeft(retval->getLeft()->removeMinNode());
	
	return retval->fixUp();
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::remove(LGTSMutableDictionaryNode *node, id key) {
	LGTSMutableDictionaryNode* retval = node;
	
	NSComparisonResult cmp = [key compare:retval->getKey()];
	
	if(cmp != NSOrderedSame && node->getCount() == 1) {
		return node;
	}
	
	if (cmp == NSOrderedAscending) {
		//FIX THIS
		if (((retval->getLeft() && retval->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
				|| !retval->getLeft())
			&& ((retval->getLeft()->getLeft() && retval->getLeft()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
				|| !retval->getLeft() || !retval->getLeft()->getLeft())) {
			retval = retval->moveRedLeft();
		}
		if (retval->getLeft()) {
			retval = retval->writeableNode();
			retval->setLeft(remove(retval->getLeft(), key));
		} else {
			retval = NULL;
		}
	} else {
		if (retval->getLeft() && retval->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
			retval = retval->writeableNode();
			retval = retval->rotateRight();
		}
			
		NSComparisonResult cmp = [key compare:retval->getKey()];

		if (cmp == NSOrderedSame && !retval->getRight()) {
			return NULL;
		}
		
		
		if (((retval->getRight() && retval->getRight()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
				|| !retval->getRight()) 
			&& ((retval->getRight() && retval->getRight()->getLeft() && retval->getRight()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorBlack)
				|| !retval->getRight() || !retval->getRight()->getLeft())) {
			retval = retval->moveRedRight();
		}
		
		cmp = [key compare:retval->getKey()];

		if (cmp == NSOrderedSame) {
			retval = retval->writeableNode();
			LGTSMutableDictionaryNode *temp = retval->getRight()->minNode();
			
			retval->setKey(temp->getKey());
			retval->setData(temp->getData());
			retval->setRight(retval->getRight()->removeMinNode());
			
		} else {
			if (retval->getRight()) {
				retval = retval->writeableNode();
				retval->setRight(remove(retval->getRight(), key));
			}
		}
	}
	
	if (retval) {
		retval = retval->fixUp();
	} else {
		retval = NULL;
	}
	
	return retval;
}

#pragma mark -
#pragma mark Insert, Remove, and Search interface for objc

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::insert(id key, id value) {
	LGTSMutableDictionaryNode *retval = NULL;
	
	retval =  insert(this, key, value);
	retval->setColor(kLGTSMutableDictionaryNodeColorBlack);
	retval->writeProtect();
	
	return retval;
}

LGTSMutableDictionaryNode *LGTSMutableDictionaryNode::nodeForKey(id key) { 
	LGTSMutableDictionaryNode *x = this; 
	while (x != NULL) {
		NSComparisonResult cmp = [key compare:x->getKey()];
		if (cmp == NSOrderedSame) {
			return x;
		} else if (cmp == NSOrderedAscending) {
			x = x->getLeft();
		} else if (cmp == NSOrderedDescending) {
			x = x->getRight();
		}
	} 
	return NULL; 
}

LGTSMutableDictionaryNode * LGTSMutableDictionaryNode::remove(id key) {
	LGTSMutableDictionaryNode *retval = remove(this, key);
	if (retval) {
		//retval = writeableNode();
		retval->setColor(kLGTSMutableDictionaryNodeColorBlack);
		retval->writeProtect();
	}
	
	return retval;
}

#pragma mark -
#pragma mark Validation and debugging

uint32_t LGTSMutableDictionaryNode::validate(void) {
	return validate(this);
}

uint32_t LGTSMutableDictionaryNode::validate(LGTSMutableDictionaryNode *node) {
	if (node->getRight() && !node->getLeft()) {
		NSLog(@"Right lean error");
	}
	
	if (node->getRight() && node->getLeft()
		&& node->getRight()->getColor() != node->getRight()->getColor()) {
		NSLog(@"Sibling color error");
	}
	
	if (node->getLeft() && node->getLeft()-node->getLeft() 
		&& node->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed
		&& node->getLeft()->getLeft()->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		NSLog(@"Double red error");
	}
	
	uint32_t left_height = 0;
	uint32_t right_height = 0;
	uint32_t height = 0;
	
	if (node->getLeft()) {
		left_height = node->getLeft()->validate();
	}
	
	if (node->getRight()) {
		right_height = node->getRight()->validate();
	}
	
	if (left_height != right_height) {
		NSLog(@"Uneven leg asert");
	}
	
	if (node->getColor() == kLGTSMutableDictionaryNodeColorRed) {
		height = left_height + 0;
	} else {
		height = left_height + 1;
	}
	
	
	return height;
}


void LGTSMutableDictionaryNode::printGraph(void) {
	NSMutableString *str = [[NSMutableString alloc] init];
	[str appendString:@"digraph LLRBtree {\n"];
	[str appendString:@"\tsize=\"6,6\";\n"];
	[str appendString:graphColors()];
	[str appendString:graphConnections()];
	[str appendString:@"}\n"];
	
	NSLog(@"Graph:\n%@", str);
	[str release];
}

NSString *LGTSMutableDictionaryNode::graphColors(void) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (getColor() == kLGTSMutableDictionaryNodeColorRed) {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=red, style=filled];\n", key, getRefCount()];
	} else {
		[str appendFormat:@"\tnode [label=\"%@\\n%ld\" color=lightblue2, style=filled];\n", key, getRefCount()];
	}
	
	[str appendFormat:@"\t\"%lx\";\n", this];
	
	if (getLeft()) {
		[str appendString:getLeft()->graphColors()];
	}
	
	if (getRight()) {
		[str appendString:getRight()->graphColors()];
	}
	
	return [str autorelease];
}

NSString *LGTSMutableDictionaryNode::graphConnections(void) {
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (getLeft()) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\"[ label = \"L\" ];\n", this, getLeft()];
	}
	
	if (getRight()) {
		[str appendFormat:@"\t\"%lx\" -> \"%lx\" [ label = \"R\" ];\n", this, getRight()];
	}
	
	if (getLeft()) {
		[str appendString:getLeft()->graphConnections()];
	}
	
	if (getRight()) {
		[str appendString:getRight()->graphConnections()];
	}
	
	return [str autorelease];
}
