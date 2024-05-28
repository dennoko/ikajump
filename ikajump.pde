import processing.sound.*;
SoundFile sounds[] = new SoundFile[5];
PImage images[] = new PImage[13];

int fps = 60;
color bgColor = color(31, 31, 95);
boolean[] keys = new boolean[128];
String scene = "pause";
int stageNum = 0;
int maxStageNum = 0;
int ballSize = 40;
int blockSize = ballSize/2;
int boxHeight = 400;
int boxNum = 5;
int totalHeight = boxHeight * boxNum;
float baseY = totalHeight - boxHeight;


void keyPressed() {
    if (key < 128) {
        keys[key] = true;
    }
    if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT || keyCode == 32) {
        keys[keyCode] = true;
    }
}

void keyReleased() {
    if (key < 128) {
        keys[key] = false;
    }
    if (keyCode == UP || keyCode == DOWN || keyCode == LEFT || keyCode == RIGHT || keyCode == 32) {
        keys[keyCode] = false;
    }
}

class Player {
    String status = "alive";
    float x, y;
    float px, py;
    float vx = 0, vy = 0;
    float maxVelocity = 5;
    float gravity = 0.5;
    int size =  ballSize;
    int radius = size / 2;
    int jumpCount = 1;
    int chargeFrame = 0;
    float maxJump = -20;

    Player(float x, float y) {
        this.x = x;
        this.y = y;
        this.px = this.x;
        this.py = this.y;
    }

    void move(int right) {
        if (right == 0) {
            vx = 0;
            return;
        }
        if (vy != 0 && status == "alive") {
            vx += maxVelocity * right;
        }
    }

    void chargeJump() {
        if (status == "alive") {
            chargeFrame++;
        }
    }

    void jump() {
        if (chargeFrame != 0 && jumpCount > 0 && status == "alive") {
            sounds[0].play();
            vy = maxJump * ((float)min(chargeFrame, fps/2) / (fps/2));
            jumpCount--;
        }
        chargeFrame = 0;
    }

    void goal() {
        sounds[1].play();
        scene = "goal";
        stageNum++;
        if (stageNum > maxStageNum) {
            stageNum = maxStageNum;
        }
    }

    void dead() {
        sounds[3].play();
        status = "dead";
        scene = "dead";
    }

    void update() {
        if (status == "alive") {
            vy += gravity;
        }
        if (vy > 0) {
            vy = min(vy, maxVelocity*8);
        } else {
            vy = max(vy, -maxVelocity*8);
        }
        px = x;
        py = y;
        y += vy;
        x += vx;
        if (x < 0) {
            x += width;            
        } else if (x > width) {
            x -= width;
        }
        if (y > totalHeight - radius) {
            y = totalHeight - radius;
            vy = 0;
        }
        
        if (y < height/2) {
            baseY = 0;
        } else if (y > totalHeight - height/2) {
            baseY = totalHeight - height;
        } else {
            baseY = y - height / 2;
        }
    }

    void display() {
        float drawY = y - baseY;
        if (-height/2 < drawY && drawY < height*3/2) {
            if (status == "dead") {
                image(images[7], x - radius, drawY - radius, size, size);
            } else {
                if (chargeFrame == 0) {
                    image(images[0], x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fps/6) {
                    image(images[1], x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fps/3) {
                    image(images[2], x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fps/2) {
                    image(images[3], x - radius, drawY - radius, size, size);
                } else {
                    int re = (chargeFrame - fps/2)/4 % 4;
                    switch (re) {
                        case 0:
                            image(images[4], x - radius, drawY - radius, size, size);
                            break;
                        case 1:
                            image(images[5], x - radius, drawY - radius, size, size);
                            break;
                        case 2:
                            image(images[6], x - radius, drawY - radius, size, size);
                            break;
                        case 3:
                            image(images[5], x - radius, drawY - radius, size, size);
                            break;
                    }
                }
            }
        }
    }
}

abstract class Item {
    boolean exists = true;
    float x, y;
    int size = ballSize;
    int radius = size / 2;

    Item(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void collision(Player player) {
        if (exists && dist(player.x, player.y, x, y) < player.radius + radius) {
            exists = false;
            event(player);
        }
    }
    abstract void event(Player player);

    abstract void display();
}

class GoalItem extends Item {
    GoalItem(float x, float y) {
        super(x, y);
    }

    void event(Player player) {
        player.goal();
    }

    void display() {
        if (exists) {
            float drawY = y - baseY;
            if (-height/2 < drawY && drawY < height*3/2) {
                image(images[8], x - radius, drawY - radius, size, size);
            }
        }
    }
}

class BoostItem extends Item {
    BoostItem(float x, float y) {
        super(x, y);
    }

    void event(Player player) {
        sounds[2].play();
        player.vy = player.maxJump;
    }
    
    void display() {
        if (exists) {
            float drawY = y - baseY;
            if (-height/2 < drawY && drawY < height*3/2) {
                image(images[12], x - radius, drawY - radius, size, size);
            }
        }
    }
}

class Star {
    float x, y, size;

    Star() {
        x = random(width);
        y = random(boxHeight);
        size = random(1, 3);
    }
    
    void display(float addY) {
        float drawY = y - baseY + addY;
        if (-height/2 < drawY && drawY < height*3/2) {
            fill(127, 95, 159);
            ellipse(x, drawY, size, size);
        }
    }
}

class Platform {
    float x, y, px, py, vx = 0, vy = 0;
    int w;
    color c = color(127, 63, 0);
    int imageNum = 9;
    Platform(float x, float y, int w) {
        this.x = x;
        this.y = y;
        this.w = w;
        px = this.x;
        py = this.y;
    }

    void collision(Player player) {
        float subX = x;
        if (subX < 0) {
            while (subX < 0) {
                subX += width;
            }
        } else if (subX >= width) {
            while (subX >= width) {
                subX -= width;
            }
        }
        if ((player.py + player.radius <= y && player.y + player.radius > y) && ((player.x + player.radius > subX && player.x - player.radius < subX + blockSize*w) || (player.x + player.radius > subX - width && player.x - player.radius < subX + blockSize*w - width))) {
            player.y = y - player.radius;
            player.vy = 0;
            player.x += this.vx;
            player.jumpCount = 1;
        }
    }

    void display() {
        float drawY = y - baseY;
        float subX = x;
        if (subX < 0) {
            while (subX < 0) {
                subX += width;
            }
        } else if (subX >= width) {
            while (subX >= width) {
                subX -= width;
            }
        }
        float endX = subX + blockSize*w;
        if (-height/2 < drawY && drawY < height*3/2) {
            for (int i = 0; i < w; i++) {
                image(images[imageNum], subX + blockSize*i, drawY, blockSize, blockSize);
            }
            if (endX > width) {
                for (int i = 0; i < w; i++) {
                    image(images[imageNum], subX - width + blockSize*i, drawY, blockSize, blockSize);
                }
            }
        }
    }
}

class MovePlatform extends Platform {
    float x0, rangeX;
    MovePlatform(float x, float y, int w, float vx, float rangeX) {
        super(x, y, w);
        this.x0 = x;
        this.vx = vx;
        this.rangeX = rangeX;
        // this.c = color(127, 127, 255);
        this.imageNum = 10;
    }

    void update() {
        px = x;
        x += vx;
        if (x > x0 + rangeX) {
            x = - x + (x0 + rangeX)*2;
            vx = -vx;
        } else if (x < x0) {
            x = - x + x0*2;
            vx = -vx;
        }

        // if (x < 0) {
        //     x += width;
        // } else if (x > width) {
        //     x -= width;
        // }
    }
}

class Acid extends Platform {
    Acid(float y, float vy) {
        super(0, y, width/blockSize);
        this.vy = vy;
        this.c = color(111, 31, 159);
    }

    void update() {
        py = y;
        y += vy;
        if (y < 0) {
            y = 0;
        }
    }

    void collision(Player player) {
        float subX = x;
        if (subX < 0) {
            while (subX < 0) {
                subX += width;
            }
        } else if (subX >= width) {
            while (subX >= width) {
                subX -= width;
            }
        }
        if ((player.py <= py && player.y > y) && ((player.x + player.radius > subX && player.x - player.radius < subX + blockSize*w) || (player.x + player.radius > subX - width && player.x - player.radius < subX + blockSize*w - width))) {
            vy = 0;
            player.vy = 0;
            player.dead();
        }
    }

    void display() {
        float drawY = y - baseY;
        float subX = x;
        if (subX < 0) {
            while (subX < 0) {
                subX += width;
            }
        } else if (subX >= width) {
            while (subX >= width) {
                subX -= width;
            }
        }
        if (-height < drawY && drawY < height*3/2) {
            fill(c);
            rect(subX, drawY+blockSize/2, blockSize*w, height);
            for (int i = 0; i < w; i++) {
                image(images[11], subX + blockSize*i, drawY, blockSize, blockSize);
            }
        }
    }
}

void loadStage(int num) {
    JSONArray stages = loadJSONArray("stages.json");
    maxStageNum = stages.size() - 1;
    JSONObject stage = stages.getJSONObject(num);;
    JSONArray platformsJSON = stage.getJSONArray("platforms");
    JSONArray movePlatformsJSON = stage.getJSONArray("movePlatforms");
    JSONArray boostItemsJSON = stage.getJSONArray("boostItems");

    stars.clear();
    platforms.clear();
    movePlatforms.clear();
    boostItems.clear();

    String bgColorHex = stage.getString("bgColor").replace("#", "");
    bgColor = unhex(bgColorHex);
    boxNum = stage.getInt("boxNum");
    totalHeight = boxHeight * boxNum;
    baseY = totalHeight - height;
    
    player = new Player(width/2, totalHeight - blockSize*2 - ballSize/2);
    goal = new GoalItem(width/2, 200);
    platforms.add(new Platform(0, totalHeight - blockSize*2, width/blockSize));
    acid = new Acid(totalHeight + height * stage.getJSONObject("acid").getFloat("y"), stage.getJSONObject("acid").getFloat("vy"));
    for (int i = 0; i < stage.getInt("starNum"); ++i) {
        stars.add(new Star());
    }
    for (int i = 0; i < platformsJSON.size(); i++) {
        JSONObject platformJSON = platformsJSON.getJSONObject(i);
        platforms.add(new Platform(width * platformJSON.getFloat("x"), totalHeight * (1.0 - platformJSON.getFloat("y")), platformJSON.getInt("w")));
    }
    for (int i = 0; i < movePlatformsJSON.size(); i++) {
        JSONObject movePlatformJSON = movePlatformsJSON.getJSONObject(i);
        movePlatforms.add(new MovePlatform(width * movePlatformJSON.getFloat("x"), totalHeight * (1.0 - movePlatformJSON.getFloat("y")), movePlatformJSON.getInt("w"), movePlatformJSON.getFloat("vx"), width * movePlatformJSON.getFloat("rangeX")));
    }
    for (int i = 0; i < boostItemsJSON.size(); i++) {
        JSONObject boostItemJSON = boostItemsJSON.getJSONObject(i);
        boostItems.add(new BoostItem(width * boostItemJSON.getFloat("x"), totalHeight * (1.0 - boostItemJSON.getFloat("y"))));
    }
}


Player player;
GoalItem goal;
Acid acid;
ArrayList<Star> stars = new ArrayList<Star>();
ArrayList<BoostItem> boostItems = new ArrayList<BoostItem>();
ArrayList<Platform> platforms = new ArrayList<Platform>();
ArrayList<MovePlatform> movePlatforms = new ArrayList<MovePlatform>();

void setup() {
    size(800, 600);
    frameRate(fps);
    background(bgColor);
    noStroke();

    sounds[0] = new SoundFile(this, "sounds/jump.mp3");
    sounds[1] = new SoundFile(this, "sounds/clear.mp3");
    sounds[2] = new SoundFile(this, "sounds/fish.mp3");
    sounds[3] = new SoundFile(this, "sounds/dead.mp3");
    sounds[4] = new SoundFile(this, "sounds/gameover.mp3");
    images[0] = loadImage("images/ika.png");
    images[1] = loadImage("images/charge1.png");
    images[2] = loadImage("images/charge2.png");
    images[3] = loadImage("images/charge3.png");
    images[4] = loadImage("images/charge4.png");
    images[5] = loadImage("images/charge5.png");
    images[6] = loadImage("images/charge6.png");
    images[7] = loadImage("images/dead.png");
    images[8] = loadImage("images/goal.png");
    images[9] = loadImage("images/block.png");
    images[10] = loadImage("images/jerry.png");
    images[11] = loadImage("images/acid.png");
    images[12] = loadImage("images/fish.png");
    
    loadStage(stageNum);
}



boolean wasSpaceKeyPressed = false;
void draw() {
    background(bgColor);
    for (Star star : stars) {
        for (int i = 0; i < boxNum; i++) {
            star.display(i*boxHeight);
        }
    }
    
    if (scene == "pause") {
        fill(255);
        textSize(50);
        text("Press Space Key to Start", width/2 - 200, height/2);
        if (keys[' '] || keys[32]) {
            scene = "game";
        }
    }
    if (scene == "game") {
        player.move(0);
        if (keys['A'] || keys['a'] || keys[LEFT]) {
            player.move(-1);
        }
        if (keys['D'] || keys['d'] || keys[RIGHT]) {
            player.move(1);
        }
        if (keys[' '] || keys[32]) {
            wasSpaceKeyPressed = true;
            player.chargeJump();
        } else if (wasSpaceKeyPressed) {
            player.jump();
            wasSpaceKeyPressed = false;
        }
        player.update();
        goal.collision(player);
        for (BoostItem boostItem : boostItems) {
            boostItem.collision(player);
        }
        for (Platform platform : platforms) {
            platform.collision(player);
        }
        for (MovePlatform movePlatform : movePlatforms) {
            movePlatform.update();
            movePlatform.collision(player);
        }
        acid.update();
        acid.collision(player);
    }
    if (scene == "goal" || scene == "dead") {
        if (keys['R'] || keys['r']) {
            loadStage(stageNum);
            scene = "game";
        }
    }

    goal.display();
    for (BoostItem boostItem : boostItems) {
        boostItem.display();
    }
    for (Platform platform : platforms) {
        platform.display();
    }
    for (MovePlatform movePlatform : movePlatforms) {
        movePlatform.display();
    }
    acid.display();
    player.display();

    if (scene == "goal") {
        fill(255);
        textSize(50);
        text("Goal!", width/2 - 50, height/2);
        textSize(20);
        text("Press R to Continue", width/2 - 100, height/2 + 50);
    }
    if (scene == "dead") {
        fill(255);
        textSize(50);
        text("Game Over", width/2 - 100, height/2);
        textSize(20);
        text("Press R to Restart", width/2 - 100, height/2 + 50);
    }
}
