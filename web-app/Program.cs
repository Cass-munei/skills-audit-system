using Google.Cloud.Firestore;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using PdfSharp.Fonts;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddSession();

// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("http://localhost:54349", "http://localhost:54349")  // Add the Flutter app's port
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});


// Add authentication services
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
})
.AddCookie("CookieAuth", options =>
{
    options.LoginPath = "/Login/Index";
    options.AccessDeniedPath = "/Login/Index";
});

// Configure Firebase Admin SDK
var firebaseConfigPath = Path.Combine(Directory.GetCurrentDirectory(), "Config", "firebase-service-account.json");
Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", firebaseConfigPath);

// Initialize Firebase Admin SDK
FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromFile(firebaseConfigPath),
    ProjectId = "skills-audit-system-a5ba3"
});

// Configure Firebase Firestore
builder.Services.AddSingleton(provider =>
{
    return FirestoreDb.Create("skills-audit-system-a5ba3");
});

// Register FirebaseApp as singleton
builder.Services.AddSingleton(FirebaseApp.DefaultInstance);

// Register Google Cloud Storage client
builder.Services.AddSingleton(provider =>
{
    var firebaseConfigPath = Path.Combine(Directory.GetCurrentDirectory(), "Config", "firebase-service-account.json");
    var credential = Google.Apis.Auth.OAuth2.GoogleCredential.FromFile(firebaseConfigPath);
    return Google.Cloud.Storage.V1.StorageClient.Create(credential);
});

// Register custom font resolver for PDF generation
GlobalFontSettings.FontResolver = new CustomFontResolver();

// Register JWT service
builder.Services.AddScoped<SkillsAuditSystem.Services.JwtService>();

// Register SentimentAnalysisService
builder.Services.AddScoped<SkillsAuditSystem.Services.SentimentAnalysisService>();

// Set the application URLs to use port 5171
builder.WebHost.UseUrls("http://localhost:5171");

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseCors("AllowAll");
app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Login}/{action=Index}/{id?}");

app.MapControllers();


app.Run();
