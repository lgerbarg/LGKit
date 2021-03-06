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

//
//  LGTSDictionaryEnumerator.mm
//  DictionaryTester
//
//  Created by Louis Gerbarg on 5/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LGTSDictionaryEnumerator.h"

@implementation LGTSDictionaryEnumerator

- (id) initWithRootNode:(LGTSMutableDictionaryNode *)node objectEnumerator:(BOOL)objectEnumerator_ {
	self = [super init];
	
	if (self) {
		objectEnumerator = objectEnumerator_;
		LGTSMutableDictionaryNode * currentNode = node;
		nodes[nodeCount] = currentNode;
		if (currentNode) {
			currentNode = LGTSMDN_Left(currentNode);

			while (currentNode) {
				nodeCount++;
				nodes[nodeCount] = currentNode;
				currentNode = LGTSMDN_Left(currentNode);
			}
		}
	}
	
	return self;
}

- (void) dealloc {
	if (nodes[0]) LGTSMDN_release(nodes[0]);
	
	[super dealloc];
}

- (id)nextObject {
	id retval = nil;
	
	if (nodeCount >= 0 && nodes[0]) {
		if (objectEnumerator) {
			retval = LGTSMDN_Data(nodes[nodeCount]);
		} else {
			retval = LGTSMDN_Key(nodes[nodeCount]);
		}
		LGTSMutableDictionaryNode *retvalNode = nodes[nodeCount];
		
		if (LGTSMDN_Right(retvalNode)) {
			nodeCount++;
			nodes[nodeCount] = LGTSMDN_Right(retvalNode);
			LGTSMutableDictionaryNode *currentNode = LGTSMDN_Left(nodes[nodeCount]);
			while (currentNode) {
				nodeCount++;
				nodes[nodeCount] = currentNode;
				currentNode = LGTSMDN_Left(currentNode);
			}
		} else {
			LGTSMutableDictionaryNode *currentNode = nodes[nodeCount];
			LGTSMutableDictionaryNode *currentNodeParent = nodes[nodeCount-1];
			
			while(LGTSMDN_Right(currentNodeParent) == currentNode) {
				nodeCount--;
				currentNode = nodes[nodeCount];
				currentNodeParent = nodes[nodeCount-1];
				
			}
			nodeCount--;
		}
	}
	
	return retval;
}

- (NSArray *)allObjects {
	NSMutableArray *retval = [NSMutableArray array];
	
	while (nodeCount >= 0 && nodes[0]) {
		if (objectEnumerator) {
			[retval addObject:LGTSMDN_Data(nodes[nodeCount])];
		} else {
			[retval addObject:LGTSMDN_Key(nodes[nodeCount])];
		}
		
		LGTSMutableDictionaryNode *retvalNode = nodes[nodeCount];
		
		if (LGTSMDN_Right(retvalNode)) {
			nodeCount++;
			nodes[nodeCount] = LGTSMDN_Right(retvalNode);
			LGTSMutableDictionaryNode *currentNode = LGTSMDN_Left(nodes[nodeCount]);
			while (currentNode) {
				nodeCount++;
				nodes[nodeCount] = currentNode;
				currentNode = LGTSMDN_Left(currentNode);
			}
		} else {
			LGTSMutableDictionaryNode *currentNode = nodes[nodeCount];
			LGTSMutableDictionaryNode *currentNodeParent = nodes[nodeCount-1];
			
			while(LGTSMDN_Right(currentNodeParent) == currentNode) {
				nodeCount--;
				currentNode = nodes[nodeCount];
				currentNodeParent = nodes[nodeCount-1];
				
			}
			nodeCount--;
		}
	}
	
	return retval;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
	NSUInteger batchCount = 0;
	
    if (state->state == 0) {
		state->state = 1;
		state->mutationsPtr = (unsigned long *)self;
    }
    
    while (nodeCount >= 0 && nodes[0] && batchCount < len) {
		if (objectEnumerator) {
			stackbuf[batchCount] = LGTSMDN_Data(nodes[nodeCount]);
		} else {
			stackbuf[batchCount] = LGTSMDN_Key(nodes[nodeCount]);
		}
		
		LGTSMutableDictionaryNode *retvalNode = nodes[nodeCount];
		
		if (LGTSMDN_Right(retvalNode)) {
			nodeCount++;
			nodes[nodeCount] = LGTSMDN_Right(retvalNode);
			LGTSMutableDictionaryNode *currentNode = LGTSMDN_Left(nodes[nodeCount]);
			while (currentNode) {
				nodeCount++;
				nodes[nodeCount] = currentNode;
				currentNode = LGTSMDN_Left(currentNode);
			}
		} else {
			LGTSMutableDictionaryNode *currentNode = nodes[nodeCount];
			LGTSMutableDictionaryNode *currentNodeParent = nodes[nodeCount-1];
			
			while(LGTSMDN_Right(currentNodeParent) == currentNode) {
				nodeCount--;
				currentNode = nodes[nodeCount];
				currentNodeParent = nodes[nodeCount-1];
				
			}
			nodeCount--;
		}
		
        batchCount++;
    }
	
    state->itemsPtr = stackbuf;
	
    return batchCount;
}

@end
