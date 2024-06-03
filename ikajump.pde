
import processing.sound.*;
JSONArray stages;
HashMap<String, SoundFile> sounds = new HashMap<String, SoundFile>();
HashMap<String, PImage> images = new HashMap<String, PImage>();

int fps = 60;
int waitFrame = 0;
boolean[] keys = new boolean[128];
color bgColor = color(31, 31, 95);
// 40block
int sketchWidth = 800;
int sketchHeight = 700;
int totalHeight = sketchHeight * 4;
float baseY = totalHeight - sketchHeight;
int ballSize = 40;
int blockSize = ballSize/2;

String scene = "pause";
int stageNum = 0;
int maxStageNum = 0;
int baseJumpCount = 1;


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
    float maxVelocity = 3;
    float gravity = 0.5;
    int size =  ballSize;
    int radius = size / 2;
    float maxJump = 21;
    int jumpCount = baseJumpCount;
    int chargeFrame = 0;
    int fullChargeFrame = fps/2;

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
            if (chargeFrame > 0) {
                vx += maxVelocity * right * 0.5;
            } else {
                vx = maxVelocity * right;
            }
        }
    }

    void chargeJump() {
        if (status == "alive") {
            chargeFrame++;
        }
    }

    void jump() {
        if (chargeFrame != 0 && jumpCount > 0 && status == "alive") {
            sounds.get("jump").play();
            vy = -maxJump * ((float)min(chargeFrame, fullChargeFrame) / fullChargeFrame);
            jumpCount--;
        }
        chargeFrame = 0;
    }

    void goal() {
        sounds.get("clear").play();
        scene = "goal";
        stageNum++;
        if (stageNum > maxStageNum) {
            stageNum = 0;
        }
    }

    void dead() {
        sounds.get("dead").play();
        vy = 0;
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
        
        if (y < height*3/5) {
            baseY = 0;
        } else if (y > totalHeight - height*2/5) {
            baseY = totalHeight - height;
        } else {
            baseY = y - height*3/5;
        }
    }

    void display() {
        float drawY = y - baseY;
        if (-radius < drawY && drawY < height + radius) {
            if (status == "dead") {
                image(images.get("dead"), x - radius, drawY - radius, size, size);
            } else {
                if (chargeFrame == 0) {
                    image(images.get("ika"), x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fullChargeFrame/3) {
                    image(images.get("charge1"), x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fullChargeFrame*2/3) {
                    image(images.get("charge2"), x - radius, drawY - radius, size, size);
                } else if (chargeFrame < fullChargeFrame) {
                    image(images.get("charge3"), x - radius, drawY - radius, size, size);
                } else {
                    int re = (chargeFrame - fullChargeFrame)/4 % 4;
                    switch (re) {
                        case 0:
                            image(images.get("charge4"), x - radius, drawY - radius, size, size);
                            break;
                        case 1:
                            image(images.get("charge5"), x - radius, drawY - radius, size, size);
                            break;
                        case 2:
                            image(images.get("charge6"), x - radius, drawY - radius, size, size);
                            break;
                        case 3:
                            image(images.get("charge5"), x - radius, drawY - radius, size, size);
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
    String imageName = "fish";

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

    void display() {
        if (exists || imageName == "goal") {
            float drawY = y - baseY;
            if (-radius < drawY && drawY < height + radius) {
                image(images.get(imageName), x - radius, drawY - radius, size, size);
            }
        }
    
    }
}

class GoalItem extends Item {
    GoalItem(float x, float y) {
        super(x, y);
        this.imageName = "goal";
    }

    void event(Player player) {
        player.goal();
    }
}

class BoostItem extends Item {
    BoostItem(float x, float y) {
        super(x, y);
        this.imageName = "fish";
    }

    void event(Player player) {
        sounds.get("fish").play();
        player.vy = -player.maxJump;
    }
}

class Star {
    float x, y, size;

    Star() {
        x = random(width);
        y = random(height);
        size = random(1, 3);
    }
    
    void display(float addY) {
        float drawY = y - baseY + addY;
        if (-size < drawY && drawY < height + size) {
            fill(127, 95, 159);
            ellipse(x, drawY, size, size);
        }
    }
}

class Platform {
    float x, y, px, py, vx = 0, vy = 0;
    int w;
    color c = color(127, 63, 0);
    String imageName = "block";
    Platform(float x, float y, int w) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.px = this.x;
        this.py = this.y;
    }

    void collision(Player player) {
        float virtualX = x;
        if (virtualX < 0) {
            while (virtualX < 0) {
                virtualX += width;
            }
        } else if (virtualX >= width) {
            while (virtualX >= width) {
                virtualX -= width;
            }
        }
        if ((player.py + player.radius <= py && y < player.y + player.radius) && ((virtualX < player.x + player.radius && player.x - player.radius < virtualX + blockSize*w) || (virtualX - width < player.x + player.radius && player.x - player.radius < virtualX + blockSize*w - width))) {
            event(player);
        }
    }
    void event(Player player) {
        player.y = this.y - player.radius;
        player.vy = 0;
        player.x += this.vx;
        player.jumpCount = baseJumpCount;
    }

    void update() {
        px = x;
        py = y;
        x += vx;
        y += vy;
    }

    void display() {
        float drawY = y - baseY;
        float virtualX = x;
        if (virtualX < 0) {
            while (virtualX < 0) {
                virtualX += width;
            }
        } else if (virtualX >= width) {
            while (virtualX >= width) {
                virtualX -= width;
            }
        }
        float endX = virtualX + blockSize*w;
        if (-blockSize < drawY && drawY < height) {
            for (int i = 0; i < w; i++) {
                image(images.get(imageName), virtualX + blockSize*i, drawY, blockSize, blockSize);
            }
            if (endX > width) {
                for (int i = 0; i < w; i++) {
                    image(images.get(imageName), virtualX - width + blockSize*i, drawY, blockSize, blockSize);
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
        this.imageName = "jerry";
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
        this.vy = -vy;
        this.c = color(111, 31, 159);
    }

    void event(Player player) {
        vy = 0;
        player.dead();
    }

    void display() {
        float drawY = y - baseY;
        if (-blockSize < drawY && drawY < height) {
            fill(c);
            rect(0, drawY+blockSize/2, width, height);
            for (int i = 0; i < w; i++) {
                image(images.get("acid"), blockSize*i, drawY, blockSize, blockSize);
            }
        }
    }
}

void loadStage(int num) {
    JSONObject stage = stages.getJSONObject(num);;
    JSONObject playerJSON = stage.getJSONObject("player");
    JSONArray platformsJSON = stage.getJSONArray("platforms");
    JSONArray movePlatformsJSON = stage.getJSONArray("movePlatforms");
    JSONArray boostItemsJSON = stage.getJSONArray("boostItems");

    stars.clear();
    platforms.clear();
    movePlatforms.clear();
    boostItems.clear();

    stageName = stage.getString("name");

    String bgColorHex = stage.getString("bgColor").replace("#", "");
    bgColor = unhex(bgColorHex);
    totalHeight = stage.getInt("height");
    if (totalHeight < height) {
        totalHeight = height;
    }
    baseY = totalHeight - height;
    
    player = new Player(playerJSON.getFloat("x"), totalHeight - playerJSON.getFloat("y"));
    player.maxVelocity = playerJSON.getFloat("v");
    player.gravity = playerJSON.getFloat("g");
    player.maxJump = playerJSON.getFloat("jump");
    baseJumpCount = playerJSON.getInt("jumpCount");
    player.jumpCount = baseJumpCount;
    player.fullChargeFrame = (int)(fps * playerJSON.getFloat("chargeTime"));

    goal = new GoalItem(stage.getJSONObject("goal").getFloat("x"), totalHeight - stage.getJSONObject("goal").getFloat("y"));
    // platforms.add(new Platform(0, totalHeight - blockSize*6, width/blockSize));
    acid = new Acid(totalHeight - stage.getJSONObject("acid").getFloat("y"), stage.getJSONObject("acid").getFloat("vy"));
    for (int i = 0; i < stage.getInt("starNum"); i++) {
        stars.add(new Star());
    }
    for (int i = 0; i < platformsJSON.size(); i++) {
        JSONObject platformJSON = platformsJSON.getJSONObject(i);
        platforms.add(new Platform(platformJSON.getFloat("x"), totalHeight - platformJSON.getFloat("y"), platformJSON.getInt("w")));
    }
    for (int i = 0; i < movePlatformsJSON.size(); i++) {
        JSONObject movePlatformJSON = movePlatformsJSON.getJSONObject(i);
        movePlatforms.add(new MovePlatform(movePlatformJSON.getFloat("x"), totalHeight - movePlatformJSON.getFloat("y"), movePlatformJSON.getInt("w"), movePlatformJSON.getFloat("vx"), movePlatformJSON.getFloat("rangeX")));
    }
    for (int i = 0; i < boostItemsJSON.size(); i++) {
        JSONObject boostItemJSON = boostItemsJSON.getJSONObject(i);
        boostItems.add(new BoostItem(boostItemJSON.getFloat("x"), totalHeight - boostItemJSON.getFloat("y")));
    }
}


String stageName = "";
Player player;
GoalItem goal;
Acid acid;
ArrayList<Star> stars = new ArrayList<Star>();
ArrayList<BoostItem> boostItems = new ArrayList<BoostItem>();
ArrayList<Platform> platforms = new ArrayList<Platform>();
ArrayList<MovePlatform> movePlatforms = new ArrayList<MovePlatform>();

void setup() {
    size(800, 700);
    frameRate(fps);
    background(bgColor);
    noStroke();

    stages = loadJSONArray("stages.json");
    maxStageNum = stages.size() - 1;
    sounds.put("jump", new SoundFile(this, "sounds/jump.mp3"));
    sounds.put("clear", new SoundFile(this, "sounds/clear.mp3"));
    sounds.put("fish", new SoundFile(this, "sounds/fish.mp3"));
    sounds.put("dead", new SoundFile(this, "sounds/dead.mp3"));
    sounds.put("gameover", new SoundFile(this, "sounds/gameover.mp3"));
    images.put("ika", loadImage("images/ika.png"));
    images.put("charge1", loadImage("images/charge1.png"));
    images.put("charge2", loadImage("images/charge2.png"));
    images.put("charge3", loadImage("images/charge3.png"));
    images.put("charge4", loadImage("images/charge4.png"));
    images.put("charge5", loadImage("images/charge5.png"));
    images.put("charge6", loadImage("images/charge6.png"));
    images.put("dead", loadImage("images/dead.png"));
    images.put("goal", loadImage("images/goal.png"));
    images.put("block", loadImage("images/block.png"));
    images.put("jerry", loadImage("images/jerry.png"));
    images.put("acid", loadImage("images/acid.png"));
    images.put("fish", loadImage("images/fish.png"));
    
    loadStage(stageNum);
}



boolean wasSpaceKeyPressed = false;
void draw() {
    background(bgColor);
    for (Star star : stars) {
        for (int i = 0; i < totalHeight; i += height) {
            star.display(i);
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
        if (keys['R'] || keys['r']) {
            player.dead();
        }
        if (keys['P'] || keys['p']) {
            if (scene == "game") {
                scene = "pause";
            }
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
        if (waitFrame > fps*3/2) {
            loadStage(stageNum);
            scene = "game";
            waitFrame = 0;
        } else {
            waitFrame++;
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
        textAlign(CENTER, CENTER);
        text("GOAL!", width/2, height/2);
    }
    if (scene == "dead") {
        fill(255);
        textSize(50);
        textAlign(CENTER, CENTER);
        text("MISS!", width/2, height/2);
    }
    if (scene == "pause") {
        fill(0, 127);
        rect(0, 0, width, height);
        fill(255);
        textSize(20);
        textAlign(CENTER, CENTER);
        text("Press Space Key to Start", width/2, height/2);
        text(stageName, width*0.1, height*0.1);
        if (keys[' '] || keys[32]) {
            if (scene == "pause") {
                scene = "game";
            }
        }
    }
}
