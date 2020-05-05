FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS base
WORKDIR /app
EXPOSE 80
# EXPOSE 443

FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
WORKDIR /src
COPY [".", "IoTReceiverAPI/"]
RUN dotnet restore "IoTReceiverAPI/IoTReceiverAPI.csproj"
WORKDIR /src/IoTReceiverAPI
RUN dotnet build "IoTReceiverAPI.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "IoTReceiverAPI.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "IoTReceiverAPI.dll"]