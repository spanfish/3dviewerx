//
//  Model.m
//  ThreeDViewer
//
//  Created by xiangwei wang on 9/28/16.
//  Copyright © 2016 xiangwei wang. All rights reserved.
//

#import "Model.h"

//坐标相减
static GLKVector3 positionSubstract(Position *vertex1, Position *vertex2) {
    GLKVector3 v = { vertex1->x - vertex2->x,
        vertex1->y - vertex2->y,
        vertex1->z - vertex2->z};
    
    return v;
}

static void triangleFaceNormal(Normal *tmpNormal, SceneVertex *vertex1, SceneVertex *vertex2, SceneVertex *vertex3) {
    GLKVector3 vectorA = positionSubstract(&(vertex2->position), &(vertex1->position));
    GLKVector3 vectorB = positionSubstract(&(vertex3->position), &(vertex1->position));
    GLKVector3 result = GLKVector3CrossProduct(vectorB, vectorA);
    
    Normal *normal1 = tmpNormal + vertex1->positionIndex;
    Normal *normal2 = tmpNormal + vertex2->positionIndex;
    Normal *normal3 = tmpNormal + vertex3->positionIndex;
#if DEBUG
    NSLog(@"1: xyz:%f,%f,%f", normal1->x, normal1->y, normal1->z);
    NSLog(@"2: xyz:%f,%f,%f", normal2->x, normal2->y, normal2->z);
    NSLog(@"3: xyz:%f,%f,%f", normal3->x, normal3->y, normal3->z);
#endif
    GLKVector3 orignalNormal;
    orignalNormal.x = normal1->x;
    orignalNormal.y = normal1->y;
    orignalNormal.z = normal1->z;
    orignalNormal = GLKVector3Add(orignalNormal, result);
    normal1->x = orignalNormal.x;
    normal1->y = orignalNormal.y;
    normal1->z = orignalNormal.z;
    
    orignalNormal.x = normal2->x;
    orignalNormal.y = normal2->y;
    orignalNormal.z = normal2->z;
    orignalNormal = GLKVector3Add(orignalNormal, result);
    normal2->x = orignalNormal.x;
    normal2->y = orignalNormal.y;
    normal2->z = orignalNormal.z;
    
    orignalNormal.x = normal3->x;
    orignalNormal.y = normal3->y;
    orignalNormal.z = normal3->z;
    orignalNormal = GLKVector3Add(orignalNormal, result);
    normal3->x = orignalNormal.x;
    normal3->y = orignalNormal.y;
    normal3->z = orignalNormal.z;
}

@implementation Material
-(NSString *) description {
    return [NSString stringWithFormat:@"name:%@\nambient:%f, %f, %f\ndiffuse:%f, %f, %f\nspectral:%f, %f, %f\nshiniess:%f", self.name, self.ambient.x, self.ambient.y, self.ambient.z,
            self.diffuse.x, self.diffuse.y, self.diffuse.z,
            self.spectral.x, self.spectral.y, self.spectral.z,
            self.shininess];
}

//默认材质
+(instancetype) defaultMaterial {
    Material *material = [[Material alloc] init];
    material.name = @"default";
    material.ambient = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
    material.diffuse = GLKVector4Make(0.7, 0.7, 0.7, 1.0);
    material.spectral = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    material.shininess = 60.0;
    
    return material;
}

//加载材料
+(NSDictionary *) loadMaterialFromFile:(NSString *) file {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSError *error = nil;
    NSString *mtlContents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    if(!error) {
        Material *material = nil;
        
        NSArray *lines = [mtlContents componentsSeparatedByString:@"\n"];
        for(NSString *line in lines) {
            if([[line lowercaseString] hasPrefix:@"newmtl"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                for(int i = 1; i < [array count]; i++) {
                    NSString *name = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([name length] > 0) {
                        material = [[Material alloc] initWithName:name];
                        [dict setObject:material forKey:name];
                        break;
                    }
                }
            } else if([[line lowercaseString] hasPrefix:@"ns"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                for(int i = 1; i < [array count]; i++) {
                    NSString *shinness = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([shinness length] > 0) {
                        material.shininess = [shinness floatValue];
                        break;
                    }
                }
            } else if([[line lowercaseString] hasPrefix:@"ka"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                float components[3] = {0};
                int j = 0;
                for(int i = 1; i < [array count]; i++) {
                    NSString *color = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([color length] > 0) {
                        components[j++] = [color floatValue];
                        if(j >= 3) {
                            break;
                        }
                    }
                }
                material.ambient = GLKVector4Make(components[0], components[1], components[2], 1.0);
            } else if([[line lowercaseString] hasPrefix:@"kd"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                float components[3] = {0};
                int j = 0;
                for(int i = 1; i < [array count]; i++) {
                    NSString *color = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([color length] > 0) {
                        components[j++] = [color floatValue];
                        if(j >= 3) {
                            break;
                        }
                    }
                }
                material.diffuse = GLKVector4Make(components[0], components[1], components[2], 1.0);
            } else if([[line lowercaseString] hasPrefix:@"ks"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                float components[3] = {0};
                int j = 0;
                for(int i = 1; i < [array count]; i++) {
                    NSString *color = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([color length] > 0) {
                        components[j++] = [color floatValue];
                        if(j >= 3) {
                            break;
                        }
                    }
                }
                material.spectral = GLKVector4Make(components[0], components[1], components[2], 1.0);
            } else if([[line lowercaseString] hasPrefix:@"map_kd"]) {
//                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                for(int i = 1; i < [array count]; i++) {
//                    NSString *texture = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                    if ([texture length] > 0) {
//                        material.kdName = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:texture];
//                        break;
//                    }
//                }
            }
        }
    }
#if DEBUG
    for (NSString *name in [dict keyEnumerator]) {
        Material *m = [dict objectForKey:name];
        NSLog(@"material:%@", m);
    }
#endif
    return dict;
}

-(instancetype) initWithName:(NSString *) name {
    self = [super init];
    if(self) {
        self.name = name;
    }
    return self;
}

-(NSString *) debugDescription {
    return [self description];
}
@end

//name: g后的名称
//materialGroup里包含这个材质的所有点
@implementation ModelGroup
-(instancetype) initWithName:(NSString *) name{
    self = [super init];
    if(self) {
        _name = name;
        _materialGroup = [NSMutableArray array];
    }
    return self;
}

-(NSString *) description {
    return [NSString stringWithFormat:@"ModelGroup name:%@, material groups:%ld", self.name, _materialGroup.count];
}

-(NSString *) debugDescription {
    return [self description];
}
@end


//name: usemtl后的名称
//materialGroup里包含这个材质的所有点
@implementation MaterialGroup

-(instancetype) initWithMaterialName:(NSString *) name {
    self = [super init];
    if(self) {
        _name = name;
        _numOfVertices = 0;
    }
    
    return self;
}

-(NSString *) description {
    return [NSString stringWithFormat:@"MaterialGroup name:%@, numOfVertices:%ld", self.name, (unsigned long)_numOfVertices];
}

-(NSString *) debugDescription {
    return [self description];
}
@end


@interface Model() {
    //文件路径
    NSString *_path;
    //面个数，一个面代表数据里的一个f行
    NSUInteger _numOfFaces;
    //顶点个数，一个顶点代表数据里的一个v行
    NSUInteger _numOfVertex;
    //纹理个数，一个顶点代表数据里的一个vt行
    NSUInteger _numOfTextcoord;
    //法线个数，一个顶点代表数据里的一个vn行
    NSUInteger _numOfNormal;
    NSUInteger _numOfTriangles;

    SceneVertex *_pVertices;
    float _minX;
    float _minY;
    float _minZ;
    float _maxX;
    float _maxY;
    float _maxZ;

    NSRegularExpression *_faceRegex;
}
@end

@implementation Model

-(instancetype) initWithPath:(NSString *) path delegate:(id<ModelDelegate>) delegate {
    self = [super init];
    if(self) {
        _path = path;
        _numOfFaces = 0;
        _numOfVertex = 0;
        _numOfTextcoord = 0;
        _numOfNormal = 0;
        _numOfTriangles = 0;
        _minX = 0;
        _minY = 0;
        _minZ = 0;
        _maxX = 0;
        _maxY = 0;
        _maxZ = 0;
        
        _pVertices = NULL;
        _hasVertexCoord = NO;
        _hasNormal = NO;

        
        _modelGroup = [NSMutableArray array];
        _materialDict = [NSMutableDictionary dictionary];
        _materialFiles = [NSMutableArray array];
        _ready = NO;
        self.delegate = delegate;
        
        _faceRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)/?([^/]*)/?([^/]*)"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
        
        
        [self importModel];
    }
    return self;
}

-(void) importModel {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAssert(_path != nil, @"path is nil");
        NSError *error = nil;
        NSString *objContents = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:&error];
        if(error) {
            [self.delegate modelDidFinishedWithError:error];
            return;
        }
        [self.delegate modelDidProcessed:@"Finding vertex"];
        //寻找所有的点数据，点数据是以v开头的行，每行有三个float数
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s)*v (.*)$" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        //顶点个数
        NSArray *matches = [regex matchesInString:objContents options:0 range:NSMakeRange(0, [objContents length])];
        _numOfVertex = [matches count];
        if(_numOfVertex == 0) {
            NSError *error = [NSError errorWithDomain:ErrorDomain code:-1 userInfo:nil];
            [self.delegate modelDidFinishedWithError:error];
            return;
        }
        
        Position *pPos = NULL;
        pPos = malloc(sizeof(Position) * _numOfVertex);

        Position *pIdx = pPos;
        int i = 0;
        for(NSTextCheckingResult *match in matches) {
            NSRange range = [match rangeAtIndex:2];
            NSString *str = [objContents substringWithRange:range];
            [self parse:str to: &(pIdx->x) size: 3];
            //找出坐标的最大和最小值
            if(i == 0) {
                _minX = _maxX = pIdx->x;
                _minY = _maxY = pIdx->y;
                _minZ = _maxZ = pIdx->z;
                i = 1;
            } else {
                if(pIdx->x > _maxX) {
                    _maxX = pIdx->x;
                }
                if(pIdx->x < _minX) {
                    _minX = pIdx->x;
                }
                if(pIdx->y > _maxY) {
                    _maxY = pIdx->y;
                }
                if(pIdx->y < _minY) {
                    _minY = pIdx->y;
                }
                if(pIdx->z > _maxZ) {
                    _maxZ = pIdx->z;
                }
                if(pIdx->z < _minZ) {
                    _minZ = pIdx->z;
                }
            }
            pIdx++;
        }

        //寻找所有的纹理数据，纹理数据是以vt开头的行，每行有2个float数
        [self.delegate modelDidProcessed:@"Finding texture"];
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s)*vt (.*)$" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        matches = [regex matchesInString:objContents options:0 range:NSMakeRange(0, [objContents length])];
        _numOfTextcoord = [matches count];
        Textcoord *pText = NULL;
        if(_numOfTextcoord > 0) {
            pText = malloc(sizeof(Textcoord) * _numOfTextcoord);
            Textcoord *pIdx = pText;
            
            for(NSTextCheckingResult *match in matches) {
                NSRange range = [match rangeAtIndex:2];
                NSString *str = [objContents substringWithRange:range];
                [self parse:str to: &(pIdx->u) size: 2];
                pIdx++;
            }
        }
        
        //寻找所有的法线数据，法线数据是以vn开头的行，每行有3个float数
        [self.delegate modelDidProcessed:@"Finding normal"];
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s)*vn (.*)$" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        matches = [regex matchesInString:objContents options:0 range:NSMakeRange(0, [objContents length])];
        _numOfNormal = [matches count];
        Normal *pNormal = NULL;
        if(_numOfNormal > 0) {
            pNormal = malloc(sizeof(Normal) * _numOfNormal);
            Normal *pIdx = pNormal;
            
            for(NSTextCheckingResult *match in matches) {
                NSRange range = [match rangeAtIndex:2];
                NSString *str = [objContents substringWithRange:range];
                [self parse:str to: &(pIdx->x) size: 3];
                pIdx++;
            }
        }
        
        //寻找所有的面
        [self.delegate modelDidProcessed:@"Finding faces"];
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s)*f\\s+(.*)$" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        matches = [regex matchesInString:objContents options:0 range:NSMakeRange(0, [objContents length])];
        for(NSTextCheckingResult *match in matches) {
            NSRange facedataRange = [match rangeAtIndex:2];
            NSString *faceStr = [objContents substringWithRange:facedataRange];
            NSArray *array = [faceStr componentsSeparatedByString:@" "];
            NSUInteger tmp = 0;

            for(NSString *str in array) {
                if([str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
                    tmp++;
                }
            }
            //三角形个数
            _numOfTriangles += tmp - 2;
        }
        
        //加载材料,材料文件必须和obj文件在一个目录下
        [self.delegate modelDidProcessed:@"Finding material"];
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s)*mtllib (.*)$" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        matches = [regex matchesInString:objContents options:0 range:NSMakeRange(0, [objContents length])];
        for(NSTextCheckingResult *match in matches) {
            NSRange mtlnameRange = [match rangeAtIndex:2];
            NSString *mtlFile = [objContents substringWithRange:mtlnameRange];
            [self.materialFiles addObject:[mtlFile lastPathComponent]];
            NSDictionary *dict = [Material loadMaterialFromFile: [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:mtlFile]];
            if([dict count]) {
                [_materialDict addEntriesFromDictionary:dict];
            }
        }
        
        long size = sizeof(SceneVertex) * _numOfTriangles * 3;
        SceneVertex *pVertices = malloc(size);
        //size = sizeof(Normal) *  _numOfTriangles * 3;
        size = sizeof(Normal) * _numOfVertex;
        Normal *tmpNormal = malloc(size);
        memset(tmpNormal, 0, size);
#if DEBUG

#endif
        BOOL firstFace = YES;
        //寻找面的正则表达式
        //面数据的格式如下：f
        //              f/vt
        //              f/vt/vn
        //              f//vn
        //可以为上面任何一种，但所有的行的格式必须是一样的，不能同时用多种格式
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)/?([^/]*)/?([^/]*)"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&error];
        
        ModelGroup *currentGroup = [[ModelGroup alloc] initWithName:@"default"];
        MaterialGroup *currentMaterialGroup = [[MaterialGroup alloc] initWithMaterialName:@"default"];
        [currentGroup.materialGroup addObject:currentMaterialGroup];
        [_modelGroup addObject:currentGroup];
 
        [self.delegate modelDidProcessed:@"Finding triangles"];
        long indexOfVertex = 0;
        for (NSString *line in [objContents componentsSeparatedByString:@"\n"]) {
            if([[line lowercaseString] hasPrefix:@"f "]) {
                //NSLog(@"vertex:%ld", indexOfVertex);
                //检查文件是否含有纹理和法线数据
                NSArray *tmpArray = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSMutableArray *array = [NSMutableArray arrayWithArray:tmpArray];
                //去掉第一个f
                [array removeObjectAtIndex:0];
                for(NSInteger i = [array count] - 1; i >= 0; i--) {
                    NSString *str = [array objectAtIndex:i];
                    //去掉空格
                    if([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
                        [array removeObjectAtIndex:i];
                    }
                }
                if([array count] == 0) {
                    continue;
                }
                if(firstFace) {
                    firstFace = NO;
                    //检查除第一个f外的数据
                    NSString *str = [array objectAtIndex:0];
                    NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
                    NSAssert([matches count] == 1, @"");
                    if([matches count] >= 1) {
                        NSTextCheckingResult *match = [matches objectAtIndex:0];
                        
                        if([match rangeAtIndex:2].length > 0) {
                            _hasVertexCoord = YES;
                        }
                        if([match rangeAtIndex:3].length > 0) {
                            _hasNormal = YES;
                        }
                    }
                }//end of firstFace

                //取得各个三角形
                //0 (i) (i + 1)  [for i in 1..(n - 2)]
                SceneVertex firstVertexOfFace = {0};
                
                [self getVertexString:[array objectAtIndex:0]
                          sceneVertex:&firstVertexOfFace
                             position:pPos
                            textcoord:pText
                               normal:pNormal];
                
                
                for(int i = 2; i < [array count]; i++) {
                    //get i-1
                    SceneVertex secondVertex = {0};
                    [self getVertexString:[array objectAtIndex: i-1]
                              sceneVertex:&secondVertex
                                 position:pPos
                                textcoord:pText
                                   normal:pNormal];
                    //get i
                    SceneVertex thirdVertex = {0};
                    [self getVertexString:[array objectAtIndex:i]
                              sceneVertex:&thirdVertex
                                 position:pPos
                                textcoord:pText
                                   normal:pNormal];
                    //add first vertex
                    memcpy(pVertices + indexOfVertex++, &firstVertexOfFace, sizeof(SceneVertex));
                    //add second vertex
                    memcpy(pVertices + indexOfVertex++, &secondVertex, sizeof(SceneVertex));
                    //add third vertex
                    memcpy(pVertices + indexOfVertex++, &thirdVertex, sizeof(SceneVertex));
                    currentMaterialGroup.numOfVertices += 3;
#if DEBUG
                    static NSInteger m = 0;
                    m++;
#endif
                    if(!_hasNormal) {
                        triangleFaceNormal(tmpNormal, &firstVertexOfFace, &secondVertex, &thirdVertex);
                    }
                }
            } /*end f line*/else if([[line lowercaseString] hasPrefix:@"g "]) {
                //group
                NSString *groupName = [[line substringFromIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if(![currentGroup.name isEqualToString:groupName]) {
                    currentGroup = [[ModelGroup alloc] initWithName:groupName];
                    if(currentMaterialGroup) {
                        currentMaterialGroup = [[MaterialGroup alloc] initWithMaterialName:currentMaterialGroup.name];
                    } else {
                        currentMaterialGroup = [[MaterialGroup alloc] initWithMaterialName:@"default"];
                    }
                    [currentGroup.materialGroup addObject:currentMaterialGroup];
                    [_modelGroup addObject:currentGroup];
                }
            } else if([[line lowercaseString] hasPrefix:@"usemtl"]) {
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                for(int i = 1; i < [array count]; i++) {
                    NSString *materialName = [[array objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([materialName length] > 0) {
                        if(![materialName isEqualToString:currentMaterialGroup.name]) {
                            currentMaterialGroup = [[MaterialGroup alloc] initWithMaterialName:materialName];
                            [currentGroup.materialGroup addObject:currentMaterialGroup];
                        }
                        break;
                    }
                }
            }
        }
        
        //normalize
        if(!_hasNormal) {
            [self.delegate modelDidProcessed:@"Calculating normal"];
            Normal *p = tmpNormal;
            for(int i = 0; i < _numOfVertex; p++, i++) {
                GLKVector3 orignalNormal;
                orignalNormal.x = p->x;
                orignalNormal.y = p->y;
                orignalNormal.z = p->z;
                orignalNormal = GLKVector3Normalize(orignalNormal);
                p->x = orignalNormal.x;
                p->y = orignalNormal.y;
                p->z = orignalNormal.z;
                
            }
            SceneVertex *pVer = pVertices;
            for(int i = 0; i < _numOfTriangles * 3; i++, pVer++) {
                memcpy(&(pVer->normal), tmpNormal+pVer->positionIndex,  sizeof(Normal));
            }
        }
        
        //_hasNormal = YES;
        _pVertices = pVertices;

        if(tmpNormal) {
            free(tmpNormal);
        }
        if(pPos) {
            free(pPos);
        }
        if(pNormal) {
            free(pNormal);
        }
        if(pText) {
            free(pText);
        }
        
        //计算模型的中心点坐标
        _center.x = (_minX + _maxX) / 2;
        _center.y = (_minY + _maxY) / 2;
        _center.z = (_minZ + _maxZ) / 2;
        
        _diameter = MAX(MAX(_maxX - _minX, _maxY - _minY), _maxZ - _minZ);
        _zDiameter = _maxZ - _minZ;
        self.ready = YES;

        [self.delegate modelDidFinishedWithError:nil];
        
    });//end of dispatch
}

-(void) getVertexString:(NSString *) faceStr
            sceneVertex:(SceneVertex *) vertex
               position:(Position *) pPos
              textcoord:(Textcoord *) pCoord
                 normal:(Normal *) pNormal {
    NSArray *matches = [_faceRegex matchesInString:faceStr options:0 range:NSMakeRange(0, [faceStr length])];
    
    NSTextCheckingResult *match = [matches firstObject];

    NSInteger vertexIndex = [[faceStr substringWithRange: [match rangeAtIndex:1]] integerValue];
    if(vertexIndex > _numOfVertex) {
        vertexIndex = vertexIndex % _numOfVertex;
    }
    NSAssert(vertexIndex > 0 && vertexIndex <= _numOfVertex, @"vertex index out of bound");
    
    vertexIndex--;
    memcpy(&(vertex->position), pPos + vertexIndex, sizeof(Position));
    vertex->positionIndex = vertexIndex;
#if DEBUG
    if(vertexIndex == 31101) {
        NSLog(@"");
    }
#endif
    if(_hasVertexCoord) {
        NSInteger textcoordIndex = [[faceStr substringWithRange: [match rangeAtIndex:2]] integerValue];
        memcpy(&(vertex->textcoord), pCoord + --textcoordIndex, sizeof(Textcoord));
    }
    
    if(_hasNormal) {
        NSInteger normalIndex = [[faceStr substringWithRange: [match rangeAtIndex:3]] integerValue];
        if(normalIndex > 0) {
            NSAssert(normalIndex > 0 && normalIndex <= _numOfNormal, @"normal index out of bound");
            memcpy(&(vertex->normal), pNormal + --normalIndex, sizeof(Normal));
        }
    }
    
    //set default color
    memset(&(vertex->color.r), 0.7, sizeof(float));
    memset(&(vertex->color.g), 0.7, sizeof(float));
    memset(&(vertex->color.b), 0.7, sizeof(float));
    memset(&(vertex->color.a), 1, sizeof(float));
}
-(void) dealloc {
    //NSLog(@"Model dealloc");
    if(_pVertices) {
        free(_pVertices);
    }
}

//从一行文字中取出size个float数，并保存到vector变量里
-(void) parse:(NSString *) line to:(float *) vector size:(NSUInteger) size {
    NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger i = 0;
    for(NSString *num in array) {
        NSString *f = [num stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([f length] > 0) {
            *vector = [f floatValue];
            vector++;
            i++;
            if(i == size) {
                break;
            }
        }
    }
    NSAssert(i == size, @"");
}
@end
