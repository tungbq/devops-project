FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /build
COPY InventoryService.csproj .
RUN dotnet restore
COPY Program.cs .
RUN dotnet publish -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .

EXPOSE 5080
ENV ASPNETCORE_URLS=http://+:5080
ENTRYPOINT ["dotnet", "InventoryService.dll"]
