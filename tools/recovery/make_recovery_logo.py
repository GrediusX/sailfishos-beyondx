from PIL import Image, ImageDraw, ImageFont
W0,H0=1024,640
def make(scale_w, scale_h, out):
    S=4  # supersample
    W,H=W0*S,H0*S
    im=Image.new("RGB",(W,H),(0,0,0)); d=ImageDraw.Draw(im)
    teal=(0,184,212); pale=(140,226,240)
    # pill outline like the original layout
    m=8*S; top=172*S; bot=468*S; lw=7*S
    d.rounded_rectangle([m,top,W-m,bot], radius=(bot-top)//2, outline=teal, width=lw)
    f=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-SemiBold.otf", 100*S)
    t="SAILFISH OS"
    # letter-spaced title centred in the pill
    sp=10*S; ws=[d.textlength(c,font=f) for c in t]; tw=sum(ws)+sp*(len(t)-1)
    x=(W-tw)/2; cy=(top+bot)/2
    for c,w in zip(t,ws):
        d.text((x,cy),c,font=f,fill=(255,255,255),anchor="lm"); x+=w+sp
    f2=ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Medium.otf", 56*S)
    t2="RECOVERY"; sp2=26*S; ws2=[d.textlength(c,font=f2) for c in t2]; tw2=sum(ws2)+sp2*(len(t2)-1)
    x=(W-tw2)/2
    for c,w in zip(t2,ws2):
        d.text((x,548*S),c,font=f2,fill=pale,anchor="lm"); x+=w+sp2
    im=im.resize((scale_w,scale_h),Image.LANCZOS)
    im.save(out)
for name,(w,h) in {"mdpi":(256,160),"hdpi":(384,240),"xhdpi":(512,320),"xxhdpi":(768,480),"xxxhdpi":(1024,640)}.items():
    make(w,h,f"logo_image_{name}.png")
print("ok")
