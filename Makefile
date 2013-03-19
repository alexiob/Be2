# Makefile for iPhone Application for Xcode gcc compiler (SDK Headers)

PROJECTNAME=Moonteers
APPFOLDER=$(PROJECTNAME).app
INSTALLFOLDER=$(PROJECTNAME).app

IPHONE_IP=10.0.2.2

SDKVER=2.2
SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk

CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD=$(CC)

LDFLAGS += -framework CoreFoundation 
LDFLAGS += -framework Foundation 
LDFLAGS += -framework UIKit 
LDFLAGS += -framework CoreGraphics
LDFLAGS += -framework QuartzCore
LDFLAGS += -framework OpenGLES
LDFLAGS += -framework OpenAL
//LDFLAGS += -framework AddressBookUI
//LDFLAGS += -framework AddressBook
//LDFLAGS += -framework GraphicsServices
//LDFLAGS += -framework CoreSurface
//LDFLAGS += -framework CoreAudio
//LDFLAGS += -framework Celestial
//LDFLAGS += -framework AudioToolbox
//LDFLAGS += -framework WebCore
//LDFLAGS += -framework WebKit
//LDFLAGS += -framework SystemConfiguration
//LDFLAGS += -framework CFNetwork
//LDFLAGS += -framework MediaPlayer
LDFLAGS += -L"$(SDK)/usr/lib"
LDFLAGS += -F"$(SDK)/System/Library/Frameworks"
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

CFLAGS += -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/gcc/arm-apple-darwin9/4.0.1/include/"
CFLAGS += -I"$(SDK)/usr/include"
CFLAGS += -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/"
CFLAGS += -I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(SDKVER).sdk/usr/include
CFLAGS += -DDEBUG -std=c99
CFLAGS += -Diphoneos_version_min=2.0
CFLAGS += -F"$(SDK)/System/Library/Frameworks"
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

CPPFLAGS=$CFLAGS

BUILDDIR=./build/$(SDKVER)
SRCDIR=./Classes
SUPPORT1=./cocos2d-iphone/cocos2d
SUPPORT2=./cocos2d-iphone/cocos2d/Support
SUPPORT3=./cocos2d-iphone/cocoslive
SUPPORT4=./cocos2d-iphone/external/Chipmunk/src
SUPPORT5=./cocos2d-iphone/external/TouchJSON
SUPPORT6=./cocos2d-iphone/external/TouchJSON/Extensions
SUPPORT7=./cocos2d-iphone/external/TouchJSON/JSON

RESDIR=./Resources
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT1)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT1)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT2)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT2)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT3)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT3)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT4)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT4)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT5)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT5)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT6)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT6)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SUPPORT7)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SUPPORT7)/*.c))
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SRCDIR)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
OBJS+=$(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))
OBJS+=$(patsubst %.m,%.o,$(wildcard *.m))
#PCH=$(wildcard *.pch)
RESOURCES+=$(wildcard ./*.png)
RESOURCES+=$(wildcard $(RESDIR)/*)
#NIBS=$(patsubst %.xib,%.nib,$(wildcard *.xib))
CFLAGS += -I"$(SUPPORT1)"
CFLAGS += -I"$(SUPPORT2)"
CFLAGS += -I"$(SUPPORT3)"
CFLAGS += -I"$(SUPPORT4)"
CFLAGS += -I"$(SUPPORT5)"
CFLAGS += -I"$(SUPPORT6)"
CFLAGS += -I"$(SUPPORT7)"

all:	$(PROJECTNAME)

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^ 

%.o:	%.m
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.cpp
	$(CPP) -c $(CPPFLAGS) $< -o $@

%.nib:	%.xib
	ibtool $< --compile $@

dist:	$(PROJECTNAME) 
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$(APPFOLDER)
	cp -r $(RESOURCES) $(BUILDDIR)/$(APPFOLDER)
	cp Info.plist $(BUILDDIR)/$(APPFOLDER)/Info.plist
	@echo "APPL????" > $(BUILDDIR)/$(APPFOLDER)/PkgInfo
	#mv $(NIBS) $(BUILDDIR)/$(APPFOLDER)
	export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate; ./ldid -S $(PROJECTNAME)
	mv $(PROJECTNAME) $(BUILDDIR)/$(APPFOLDER)

install: dist
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER)'
	scp -r $(BUILDDIR)/$(APPFOLDER) root@$(IPHONE_IP):/Applications/$(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed, please respring iPhone"
	ssh root@$(IPHONE_IP) 'respring'

install_respring:
	scp respring root@$(IPHONE_IP):/usr/bin/respring

uninstall:
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER); respring'
	@echo "Application $(INSTALLFOLDER) uninstalled, please respring iPhone"

clean:
	@rm -f $(SRCDIR)/*.o *.o $(SUPPORT1)/*.o $(SUPPORT2)/*.o $(SUPPORT3)/*.o $(SUPPORT4)/*.o $(SUPPORT5)/*.o $(SUPPORT6)/*.o $(SUPPORT7)/*.o
	@rm -rf $(BUILDDIR)
	@rm -f $(PROJECTNAME)

